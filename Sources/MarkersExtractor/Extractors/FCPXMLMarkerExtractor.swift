import CoreMedia
import Foundation
import Logging
import Pipeline
import TimecodeKit

class FCPXMLMarkerExtractor {
    private let logger = Logger(label: "\(FCPXMLMarkerExtractor.self)")

    let fcpxmlDoc: XMLDocument
    let idNamingMode: MarkerIDMode

    required init(_ fcpxml: URL, _ idNamingMode: MarkerIDMode) throws {
        fcpxmlDoc = try XMLDocument(contentsOfFCPXML: fcpxml)
        self.idNamingMode = idNamingMode
    }
    
    required init(_ fcpxml: XMLDocument, _ idNamingMode: MarkerIDMode) throws {
        fcpxmlDoc = fcpxml
        self.idNamingMode = idNamingMode
    }

    static func extractMarkers(from fcpxml: FCPXMLFile, idNamingMode: MarkerIDMode) throws -> [Marker] {
        let data = try fcpxml.data()
        let xml = try XMLDocument(data: data)
        return try self.init(xml, idNamingMode).extractMarkers()
    }
    
    static func extractMarkers(from fcpxml: URL, idNamingMode: MarkerIDMode) throws -> [Marker] {
        try self.init(fcpxml, idNamingMode).extractMarkers()
    }

    public func extractMarkers() -> [Marker] {
        var fcpxmlMarkers: [Marker] = []

        // TODO: Shouldn't there be only one project?
        for project in fcpxmlDoc.fcpxAllProjects {
            fcpxmlMarkers += extractProjectMarkers(project).compactMap(convertMarker)
        }

        return fcpxmlMarkers
    }

    private func extractProjectMarkers(_ project: XMLElement) -> [XMLElement] {
        var markers: [XMLElement] = []

        let eventChildrenElements = project.subelements(
            forName: "marker",
            usingAbsoluteMatch: false
        )

        markers += FCPXMLUtility().filter(
            fcpxElements: eventChildrenElements,
            ofTypes: [.marker, .chapterMarker]
        )

        return markers
    }

    private func convertMarker(_ markerXML: XMLElement) -> Marker? {
        // Marker must be inside a timeline
        guard let parentProject = findParentByType(markerXML, .project) else {
            return nil
        }

        let parentClip = markerXML.parentElement!
        let parentEvent = findParentByType(parentClip, .event)!
        let parentLibrary = parentEvent.parentElement!

        let type = getMarkerType(markerXML)

        let fps = getParentFPS(markerXML)
        let parentDuration = (try? parentClip.fcpxDuration?.toTimecode(at: fps)) ?? .init(at: fps)
        let position = calcMarkerPosition(markerXML, parentFPS: fps, parentDuration: parentDuration)
        let roles = getClipRoles(parentClip)
        
        return Marker(
            type: type,
            name: markerXML.fcpxValue ?? "",
            notes: markerXML.fcpxNote ?? "",
            roles: roles,
            position: position,
            parentInfo: Marker.ParentInfo(
                clipName: getClipName(parentClip),
                clipDuration: parentDuration,
                eventName: parentEvent.fcpxName ?? "",
                projectName: parentProject.fcpxName ?? "",
                libraryName: getLibraryName(parentLibrary) ?? ""
            )
        )
    }

    private func calcMarkerPosition(_ marker: XMLElement,
                                    parentFPS: TimecodeFrameRate,
                                    parentDuration: Timecode) -> Timecode {
        let parentClip = marker.parentElement!
        
        let localInPoint: CMTime = parentClip.fcpxStartValue.seconds > 0
            ? marker.fcpxLocalInPoint - parentClip.fcpxStartValue
            : marker.fcpxLocalInPoint

        let markerPosition = CMTimeAdd(parentClip.fcpxTimelineInPoint!, localInPoint)
        let timecode: Timecode = {
            guard let tc = try? markerPosition.toTimecode(at: parentFPS) else {
                let markerName = marker.fcpxValue ?? ""
                let clipName = getClipName(parentClip)
                logger.warning("Could not form position timecode for marker \(markerName.quoted) in clip \(clipName.quoted).")
                return .init(at: parentFPS)
            }
            return tc
        }()

        if localInPoint.seconds > parentDuration.realTimeValue {
            logger.warning("Marker at \(timecode) is out of bounds of its parent clip.")
        }

        return timecode
    }

    private func getParentFPS(_ marker: XMLElement) -> TimecodeFrameRate {
        let defaultFPS: TimecodeFrameRate = ._24

        guard let parent = findParentByType(marker, .sequence) else {
            logger.warning("Couldn't parse format FPS; using \(defaultFPS.stringValue) to form marker timecode.")
            return defaultFPS
        }
        
        let isFPSDrop: Bool = {
            switch parent.fcpxTCFormat {
            case .dropFrame:
                return true
            case .nonDropFrame:
                return false
            case nil:
                logger.warning("Couldn't detect whether FPS is drop (DF) or non-drop (NDF); using NDF to form marker timecode.")
                return false
            }
        }()
        
        guard let frameDuration = parent.formatValues()?.frameDuration,
              let videoRate = VideoFrameRate(frameDuration: frameDuration),
              let timecodeRate = videoRate.timecodeFrameRate(drop: isFPSDrop)
        else {
            logger.warning("Couldn't parse format FPS; using \(defaultFPS.stringValue) to form marker timecode.")
            return defaultFPS
        }
        
        return timecodeRate
    }

    private func findParentByType(
        _ element: XMLElement,
        _ type: FCPXMLElementType
    ) -> XMLElement? {
        guard let parent = element.parentElement else {
            return nil
        }

        return parent.fcpxType == type ? parent : findParentByType(parent, type)
    }

    private func getClipName(_ clip: XMLElement) -> String {
        guard let clipName = clip.fcpxName else {
            return ""
        }

        if let clipMediaSrc = clip.fcpxResource?.subElement(named: "media-rep")?.fcpxSrc {
            return "\(clipName).\(clipMediaSrc.fileExtension)"
        }

        return clipName
    }

    private func getLibraryName(_ library: XMLElement) -> String? {
        // will be a file URL that is URL encoded
        guard let location = library.getElementAttribute("location") else {
            return nil
        }
        
        let libName = URL(fileURLWithPath: location)
            .deletingPathExtension()
            .lastPathComponent
        
        // decode URL encoding
        let libNameDecoded = libName.removingPercentEncoding ?? libName
        
        return libNameDecoded
    }

    private func getMarkerType(_ marker: XMLElement) -> MarkerType {
        if marker.fcpxType == .chapterMarker {
            return .chapter
        }

        // "completed" attribute is only present if marker is a To Do
        if let completed = marker.getElementAttribute("completed") {
            return .todo(completed: completed == "1")
        }

        return .standard
    }

    private func getClipRoles(_ clip: XMLElement) -> [MarkerRole] {
        if let acSourceRole = clip.subElement(named: "audio-channel-source")?.fcpxRole {
            return [acSourceRole].map { .audio($0.localizedCapitalized) }
        }

        // gather
        
        let audioRolesPool = [
            clip.getElementAttribute("audioRole"),
            clip.subElement(named: "video")?.subElement(named: "audio")?.fcpxRole, // TODO: ??
            clip.subElement(named: "audio")?.fcpxRole
        ].compactMap { $0?.localizedCapitalized }
        
        var videoRolesPool = [
            clip.getElementAttribute("videoRole"),
            clip.subElement(named: "video")?.fcpxRole,
            clip.fcpxRole
        ].compactMap { $0?.localizedCapitalized }

        if clip.name == "title" && videoRolesPool.compactMap({ $0 }).isEmpty {
            videoRolesPool.append("Titles")
        }

        // pack into enum cases
        
        let videoRoles: [MarkerRole] = videoRolesPool
            .sorted()
            .map { .video($0) }
        
        let audioRoles: [MarkerRole] = audioRolesPool
            .sorted()
            .map { .audio($0) }
        
        // return
        
        return videoRoles + audioRoles
    }
}
