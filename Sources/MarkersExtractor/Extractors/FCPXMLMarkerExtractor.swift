import CoreMedia
import Foundation
import Logging
import Pipeline

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

        // Shouldn't there be only one project?
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

        let position = calcMarkerPosition(markerXML)
        let fps = getParentFPS(markerXML)
        let roles = getClipRoles(parentClip).joined(separator: ", ")

        return Marker(
            type: type,
            name: markerXML.fcpxValue ?? "",
            notes: markerXML.fcpxNote ?? "",
            role: roles,
            status: status,
            checked: isChecked,
            position: position,
            fps: fps,
            parentClipName: getClipName(parentClip),
            parentClipDuration: parentClip.fcpxDuration!,
            parentEventName: parentEvent.fcpxName ?? "",
            parentProjectName: parentProject.fcpxName ?? "",
            parentLibraryName: getLibraryName(parentLibrary) ?? "",
            nameMode: idNamingMode
        )
    }

    private func calcMarkerPosition(_ marker: XMLElement) -> CMTime {
        let parentClip = marker.parentElement!

        let localInPoint: CMTime

        if parentClip.fcpxStartValue.seconds > 0 {
            localInPoint = marker.fcpxLocalInPoint - parentClip.fcpxStartValue
        } else {
            localInPoint = marker.fcpxLocalInPoint
        }

        let markerPosition = CMTimeAdd(parentClip.fcpxTimelineInPoint!, localInPoint)

        if localInPoint.seconds > parentClip.fcpxDuration!.seconds {
            let fps = getParentFPS(marker)
            let timecode = markerPosition.timeAsTimecode(usingFrameDuration: fps, dropFrame: false)
                .timecodeString
            logger.warning("Marker at \(timecode) is out of bounds of it's parent clip")
        }

        return CMTimeAdd(parentClip.fcpxTimelineInPoint!, localInPoint)
    }

    private func getParentFPS(_ marker: XMLElement) -> CMTime {
        let defaultFPS = CMTime(value: 1001, timescale: 24000)

        guard let fps = findParentByType(marker, .sequence)?.formatValues()?.frameDuration else {
            logger.warning("Couldn't parse format FPS, using 24fps to calculate marker timecode")
            return defaultFPS
        }

        return fps
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
