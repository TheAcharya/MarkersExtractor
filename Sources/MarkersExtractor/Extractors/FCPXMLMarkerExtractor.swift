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
        let isChecked = (type == .todo && markerXML.getElementAttribute("completed") == "1")
        let status = getStatus(type, isChecked)

        let fps = getParentFPS(markerXML)
        let parentDuration = (try? parentClip.fcpxDuration?.toTimecode(at: fps)) ?? .init(at: fps)
        let position = calcMarkerPosition(markerXML, parentFPS: fps, parentDuration: parentDuration)
        let roles = getClipRoles(parentClip).joined(separator: ", ")
        
        return Marker(
            type: type,
            name: markerXML.fcpxValue ?? "",
            notes: markerXML.fcpxNote ?? "",
            role: roles,
            status: status,
            checked: isChecked,
            position: position,
            nameMode: idNamingMode,
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
        let timecode = (try? markerPosition.toTimecode(at: parentFPS)) ?? .init(at: parentFPS)

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
        guard let location = library.getElementAttribute("location") else {
            return nil
        }

        return URL(fileURLWithPath: location).lastPathComponent
    }

    private func getMarkerType(_ marker: XMLElement) -> MarkerType {
        if marker.fcpxType == .chapterMarker {
            return .chapter
        }

        if marker.getElementAttribute("completed") != nil {
            return .todo
        }

        return .standard
    }

    private func getClipRoles(_ clip: XMLElement) -> [String] {
        if let acSourceRole = clip.subElement(named: "audio-channel-source")?.fcpxRole {
            return [acSourceRole].map { $0.localizedCapitalized }
        }

        var roles: Set<String?> = [
            clip.getElementAttribute("audioRole"),
            clip.getElementAttribute("videoRole"),
            clip.fcpxRole,
            clip.subElement(named: "video")?.subElement(named: "audio")?.fcpxRole,
            clip.subElement(named: "video")?.fcpxRole,
            clip.subElement(named: "audio")?.fcpxRole,
        ]

        if clip.name == "title" && roles.compactMap({ $0 }).isEmpty {
            roles.insert("Titles")
        }

        // Clean out all nil and return sorted array
        return roles.compactMap { $0?.localizedCapitalized }.sorted()
    }

    private func getStatus(_ markerType: MarkerType, _ isChecked: Bool) -> MarkerStatus {
        switch markerType {
        case .standard:
            return .notStarted
        case .todo:
            return isChecked ? .done : .inProgress
        case .chapter:
            return .notStarted
        }
    }
}
