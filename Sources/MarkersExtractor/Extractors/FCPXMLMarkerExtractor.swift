//
//  FCPXMLMarkerExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import Foundation
import Logging
import Pipeline
import TimecodeKit

class FCPXMLMarkerExtractor {
    private let logger: Logger

    let fcpxmlDoc: XMLDocument
    let idNamingMode: MarkerIDMode
    let includeOutsideClipBoundaries: Bool
    let excludeRoleType: MarkerRoleType?
    let enableSubframes: Bool
    
    // MARK: - Init
    
    required init(
        fcpxml: XMLDocument,
        idNamingMode: MarkerIDMode,
        includeOutsideClipBoundaries: Bool,
        excludeRoleType: MarkerRoleType?,
        enableSubframes: Bool,
        logger: Logger? = nil
    ) throws {
        self.logger = logger ?? Logger(label: "\(Self.self)")
        
        fcpxmlDoc = fcpxml
        self.idNamingMode = idNamingMode
        self.includeOutsideClipBoundaries = includeOutsideClipBoundaries
        self.excludeRoleType = excludeRoleType
        self.enableSubframes = enableSubframes
    }
    
    required convenience init(
        fcpxml: URL,
        idNamingMode: MarkerIDMode,
        includeOutsideClipBoundaries: Bool,
        excludeRoleType: MarkerRoleType?,
        enableSubframes: Bool,
        logger: Logger? = nil
    ) throws {
        let xml = try XMLDocument(contentsOfFCPXML: fcpxml)
        try self.init(
            fcpxml: xml,
            idNamingMode: idNamingMode,
            includeOutsideClipBoundaries: includeOutsideClipBoundaries,
            excludeRoleType: excludeRoleType,
            enableSubframes: enableSubframes,
            logger: logger
        )
    }
    
    required convenience init(
        fcpxml: FCPXMLFile,
        idNamingMode: MarkerIDMode,
        includeOutsideClipBoundaries: Bool,
        excludeRoleType: MarkerRoleType?,
        enableSubframes: Bool,
        logger: Logger? = nil
    ) throws {
        let data = try fcpxml.data()
        let xml = try XMLDocument(data: data)
        try self.init(
            fcpxml: xml,
            idNamingMode: idNamingMode,
            includeOutsideClipBoundaries: includeOutsideClipBoundaries,
            excludeRoleType: excludeRoleType,
            enableSubframes: enableSubframes,
            logger: logger
        )
    }
    
    // MARK: - Public Instance Methods

    public func extractMarkers() -> [Marker] {
        var fcpxmlMarkers: [Marker] = []

        // TODO: Shouldn't there be only one project?
        for project in fcpxmlDoc.fcpxAllProjects {
            fcpxmlMarkers += extractAllXMLMarkers(project: project).compactMap(convertMarker)
        }

        // apply role filter
        if let excludeRoleType = excludeRoleType {
            logger.info("Excluding all roles of \(excludeRoleType.rawValue) type.")
            
            let beforeMarkerCount = fcpxmlMarkers.count
            
            fcpxmlMarkers = fcpxmlMarkers.filter { marker in
                switch excludeRoleType {
                case .video:
                    if marker.roles.isVideoEmpty { return true }
                    if marker.roles.isVideoDefault { return false }
                    return false
                case .audio:
                    if marker.roles.isAudioEmpty { return true }
                    if marker.roles.isAudioDefault { return false }
                    return false
                }
            }
            
            let countDiff = beforeMarkerCount - fcpxmlMarkers.count
            if countDiff > 0 {
                logger.info("Omitted \(countDiff) markers with \(excludeRoleType.rawValue) type.")
            }
        }
        
        // apply out-of-bounds filter
        if !includeOutsideClipBoundaries {
            let (kept, omitted): ([Marker], [Marker]) = fcpxmlMarkers
                .reduce(into: ([], [])) { base, marker in
                    marker.isOutOfClipBounds()
                        ? base.1.append(marker)
                        : base.0.append(marker)
                }
            
            // remove out-of-bounds markers from output
            fcpxmlMarkers = kept
            
            // emit log messages for out-of-bounds markers
            omitted.forEach { marker in
                logger.notice(
                    "Marker \(marker.name.quoted) at \(marker.position) is out of bounds of its parent clip \(marker.parentInfo.clipName) (\(marker.parentInfo.clipInTime) - \(marker.parentInfo.clipOutTime)) and will be omitted."
                )
            }
        }
        
        return fcpxmlMarkers
    }
    
    // MARK: - Private Methods

    private func extractAllXMLMarkers(project: XMLElement) -> [XMLElement] {
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
        
        guard let parentClip = markerXML.parentElement,
              let parentEvent = findParentByType(parentClip, .event),
              let parentLibrary = parentEvent.parentElement
        else { return nil }
        
        let type = getMarkerType(markerXML)

        let fps = getParentFPS(markerXML)
        
        let parentInTime: Timecode = {
            guard let time = parentClip.fcpxTimelineInPoint,
                  let tc = try? formTimecode(time, at: fps)
            else { return formTimecode(at: fps) }
            return tc
        }()
        
        // TODO: in complex FCPXML, `fcpxTimelineOutPoint` is sometimes incorrect, so we need to workaround it by using clip duration instead
        let parentOutTime: Timecode = {
            guard let dur = parentClip.fcpxDuration,
                  let tc = try? formTimecode(dur, at: fps)
            else { return parentInTime + formTimecode(at: fps) }
            return parentInTime + tc
        }()
        
        let position = calcMarkerPosition(
            markerXML,
            parentFPS: fps,
            parentInTime: parentInTime,
            parentOutTime: parentOutTime
        )
        
        let roles = getClipRoles(parentClip)
        
        return Marker(
            type: type,
            name: markerXML.fcpxValue ?? "",
            notes: markerXML.fcpxNote ?? "",
            roles: roles,
            position: position,
            parentInfo: Marker.ParentInfo(
                clipName: getClipName(parentClip),
                clipFilename: getClipFilename(parentClip) ?? "",
                clipInTime: parentInTime,
                clipOutTime: parentOutTime,
                eventName: parentEvent.fcpxName ?? "",
                projectName: parentProject.fcpxName ?? "",
                libraryName: getLibraryName(parentLibrary) ?? ""
            )
        )
    }

    private func calcMarkerPosition(
        _ marker: XMLElement,
        parentFPS: TimecodeFrameRate,
        parentInTime: Timecode,
        parentOutTime: Timecode
    ) -> Timecode {
        let markerName = marker.fcpxValue ?? ""
        
        guard let parentClip = marker.parentElement else {
            logger.warning(
                "Could not find parent element while attempting to form position timecode for marker \(markerName.quoted)."
            )
            return .init(at: parentFPS)
        }
        
        // FYI: clips can be resized from either side so it's possible for out-of-boundary
        // markers to exist prior to the clip's start time or after the clip's end time,
        // as FCP still exports them to the XML even though they are not visible in the FCP timeline
        
        let localInPoint: CMTime = parentClip.fcpxStartValue.seconds > 0
            ? marker.fcpxLocalInPoint - parentClip.fcpxStartValue
            : marker.fcpxLocalInPoint

        let markerCMTime = CMTimeAdd(parentClip.fcpxTimelineInPoint!, localInPoint)
        let clipName = getClipName(parentClip)
        let markerTimecode: Timecode = {
            guard let tc = try? formTimecodeInterval(markerCMTime, at: parentFPS).flattened()
            else {
                logger.warning(
                    "Could not form position timecode for marker \(markerName.quoted) in clip \(clipName.quoted)."
                )
                return .init(at: parentFPS)
            }
            return tc
        }()

        return markerTimecode
    }

    private func getParentFPS(_ marker: XMLElement) -> TimecodeFrameRate {
        let defaultFPS: TimecodeFrameRate = ._24

        guard let parent = findParentByType(marker, .sequence) else {
            logger.warning(
                "Couldn't parse format FPS; using \(defaultFPS.stringValue) to form marker timecode."
            )
            return defaultFPS
        }
        
        let isFPSDrop: Bool = {
            switch parent.fcpxTCFormat {
            case .dropFrame:
                return true
            case .nonDropFrame:
                return false
            case nil:
                logger.warning(
                    "Couldn't detect whether FPS is drop (DF) or non-drop (NDF); using NDF to form marker timecode."
                )
                return false
            }
        }()
        
        guard let frameDuration = parent.formatValues()?.frameDuration,
              let videoRate = VideoFrameRate(frameDuration: frameDuration),
              let timecodeRate = videoRate.timecodeFrameRate(drop: isFPSDrop)
        else {
            logger.warning(
                "Couldn't parse format FPS; using \(defaultFPS.stringValue) to form marker timecode."
            )
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
        clip.fcpxName ?? ""
    }
    
    private func getClipFilename(_ clip: XMLElement) -> String? {
        clip.fcpxResource?.subElement(named: "media-rep")?.fcpxSrc?.lastPathComponent ?? ""
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

    internal func getClipRoles(_ clip: XMLElement) -> MarkerRoles {
        // handle special case of audio-channel-source XML element
        if let acSourceRole = clip.subElement(named: "audio-channel-source")?.fcpxRole {
            return MarkerRoles(
                video: nil,
                isVideoDefault: false,
                audio: acSourceRole.localizedCapitalized,
                isAudioDefault: false,
                collapseSubroles: true
            )
        }
        
        var isVideoDefault = false
        var isAudioDefault = false
        
        // gather
        
        var videoRolesPool = [
            clip.getElementAttribute("videoRole"),
            clip.subElement(named: "video")?.fcpxRole,
            clip.fcpxRole
        ]
            .compactMap { $0?.localizedCapitalized }
            .filter { !$0.isEmpty }
        
        var audioRolesPool = [
            clip.getElementAttribute("audioRole"),
            clip.subElement(named: "video")?.subElement(named: "audio")?.fcpxRole, // TODO: ??
            clip.subElement(named: "audio")?.fcpxRole
        ]
            .compactMap { $0?.localizedCapitalized }
            .filter { !$0.isEmpty }
        
        // assign defaults if needed
        if let clipType = clip.name,
           let defaultRoles = MarkerRoles(defaultForClipType: clipType)
        {
            if videoRolesPool.isEmpty, let r = defaultRoles.video {
                isVideoDefault = true
                videoRolesPool.append(r)
            }
            if audioRolesPool.isEmpty, let r = defaultRoles.audio {
                isAudioDefault = true
                audioRolesPool.append(r)
            }
        }
        
        // sort
        let videoRole: String? = videoRolesPool
            .filter { !$0.isEmpty }
            .sorted()
            .first
        let audioRole: String? = audioRolesPool
            .filter { !$0.isEmpty }
            .sorted()
            .first
        
        // return
        
        return MarkerRoles(
            video: videoRole,
            isVideoDefault: isVideoDefault,
            audio: audioRole,
            isAudioDefault: isAudioDefault,
            collapseSubroles: true
        )
    }
    
    private func formTimecode(
        at frameRate: TimecodeFrameRate
    ) -> Timecode {
        Timecode(
            at: frameRate,
            limit: ._24hours,
            base: ._80SubFrames,
            format: enableSubframes ? [.showSubFrames] : .default()
        )
    }
    
    private func formTimecode(
        _ cmTime: CMTime,
        at frameRate: TimecodeFrameRate
    ) throws -> Timecode {
        try cmTime.toTimecode(
            at: frameRate,
            limit: ._24hours,
            base: ._80SubFrames,
            format: enableSubframes ? [.showSubFrames] : .default()
        )
    }
    
    private func formTimecodeInterval(
        _ cmTime: CMTime,
        at frameRate: TimecodeFrameRate
    ) throws -> TimecodeInterval {
        try TimecodeInterval(
            cmTime,
            at: frameRate,
            limit: ._24hours,
            base: ._80SubFrames,
            format: enableSubframes ? [.showSubFrames] : .default()
        )
    }
}
