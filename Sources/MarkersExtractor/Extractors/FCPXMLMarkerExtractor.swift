//
//  FCPXMLMarkerExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import Foundation
import Logging
import DAWFileKit
import TimecodeKit

class FCPXMLMarkerExtractor: NSObject, ProgressReporting {
    private let logger: Logger
    public let progress: Progress
    
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
    ) {
        self.logger = logger ?? Logger(label: "\(Self.self)")
        progress = Progress()
        
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
        let xml = try XMLDocument(contentsOf: fcpxml)
        self.init(
            fcpxml: xml,
            idNamingMode: idNamingMode,
            includeOutsideClipBoundaries: includeOutsideClipBoundaries,
            excludeRoleType: excludeRoleType,
            enableSubframes: enableSubframes,
            logger: logger
        )
    }
    
    required convenience init(
        fcpxml: inout FCPXMLFile,
        idNamingMode: MarkerIDMode,
        includeOutsideClipBoundaries: Bool,
        excludeRoleType: MarkerRoleType?,
        enableSubframes: Bool,
        logger: Logger? = nil
    ) throws {
        let xml = try fcpxml.xmlDocument()
        self.init(
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
        progress.completedUnitCount = 0
        progress.totalUnitCount = 1
        
        defer { progress.completedUnitCount = 1 }
        
        var fcpxmlMarkers: [Marker] = []

        let parsedFCPXML = FinalCutPro.FCPXML(fileContent: fcpxmlDoc)
        
        let library = parsedFCPXML.library(context: MarkersExtractor.elementContext)
        
        for event in parsedFCPXML.allEvents(context: MarkersExtractor.elementContext) {
            fcpxmlMarkers += markers(in: event, library: library)
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
                let mn = marker.name.quoted
                let pos = marker.position
                let clipName = marker.parentInfo.clipName.quoted
                let inTime = marker.parentInfo.clipInTime
                let outTime = marker.parentInfo.clipOutTime
                logger.notice(
                    "Marker \(mn) at \(pos) is out of bounds of its parent clip \(clipName) (\(inTime) - \(outTime)) and will be omitted."
                )
            }
        }
        
        return fcpxmlMarkers
    }
    
    // MARK: - Private Methods

    private func markers(
        in event: FinalCutPro.FCPXML.Event,
        library: FinalCutPro.FCPXML.Library?
    ) -> [Marker] {
        let settings = FinalCutPro.FCPXML.ExtractionSettings(
            // deep: true,
            excludeTypes: [],
            auditionMask: .activeAudition
        )
        let extractedMarkers = event.extractMarkers(settings: settings, ancestorsOfParent: [])
        
        return extractedMarkers.compactMap {
            convertMarker(
                $0,
                // parentEvent: event,
                parentLibrary: library
            )
        }
    }
    
    private func convertMarker(
        _ extractedMarker: FinalCutPro.FCPXML.Marker,
        // parentEvent: FinalCutPro.FCPXML.Event,
        parentLibrary: FinalCutPro.FCPXML.Library?
    ) -> Marker? {
        // let roles = getClipRoles(parentClip)
        
        guard let position = extractedMarker.context[.absoluteStart],
              let clipInTime = extractedMarker.context[.parentAbsoluteStart],
              let clipDuration = extractedMarker.context[.parentDuration],
              let clipOutTime = try? clipInTime.adding(clipDuration, by: .wrapping)
        else {
            logger.error("Error converting marker: \(extractedMarker.name.quoted).")
            return nil
        }
        
        return Marker(
            type: extractedMarker.metaData,
            name: extractedMarker.name,
            notes: extractedMarker.note ?? "",
            roles: MarkerRoles(video: "NOT YET IMPLEMENTED"), // TODO: implement
            position: position,
            parentInfo: Marker.ParentInfo(
                clipName: extractedMarker.context[.parentName] ?? "",
                clipFilename: extractedMarker.context[.mediaFilename] ?? "",
                clipInTime: clipInTime,
                clipOutTime: clipOutTime,
                eventName: extractedMarker.context[.ancestorEventName] ?? "",
                projectName: extractedMarker.context[.ancestorProjectName] ?? "",
                libraryName: parentLibrary?.name ?? ""
            )
        )
    }
    
    // TODO: delete commented code after refactoring roles parsing in DAWFileKit
//    internal func getClipRoles(_ clip: XMLElement) -> MarkerRoles {
//        // handle special case of audio-channel-source XML element
//        if let acSourceRole = clip.subElement(named: "audio-channel-source")?.fcpxRole {
//            return MarkerRoles(
//                video: nil,
//                isVideoDefault: false,
//                audio: acSourceRole.localizedCapitalized,
//                isAudioDefault: false,
//                collapseSubroles: true
//            )
//        }
//        
//        var isVideoDefault = false
//        var isAudioDefault = false
//        
//        // gather
//        
//        var videoRolesPool = [
//            clip.getElementAttribute("videoRole"),
//            clip.subElement(named: "video")?.fcpxRole,
//            clip.fcpxRole
//        ]
//            .compactMap { $0?.localizedCapitalized }
//            .filter { !$0.isEmpty }
//        
//        var audioRolesPool = [
//            clip.getElementAttribute("audioRole"),
//            clip.subElement(named: "video")?.subElement(named: "audio")?.fcpxRole, // TODO: ??
//            clip.subElement(named: "audio")?.fcpxRole
//        ]
//            .compactMap { $0?.localizedCapitalized }
//            .filter { !$0.isEmpty }
//        
//        // assign defaults if needed
//        if let clipType = clip.name,
//           let defaultRoles = MarkerRoles(defaultForClipType: clipType)
//        {
//            if videoRolesPool.isEmpty, let r = defaultRoles.video {
//                isVideoDefault = true
//                videoRolesPool.append(r)
//            }
//            if audioRolesPool.isEmpty, let r = defaultRoles.audio {
//                isAudioDefault = true
//                audioRolesPool.append(r)
//            }
//        }
//        
//        // sort
//        let videoRole: String? = videoRolesPool
//            .filter { !$0.isEmpty }
//            .sorted()
//            .first
//        let audioRole: String? = audioRolesPool
//            .filter { !$0.isEmpty }
//            .sorted()
//            .first
//        
//        // return
//        
//        return MarkerRoles(
//            video: videoRole,
//            isVideoDefault: isVideoDefault,
//            audio: audioRole,
//            isAudioDefault: isAudioDefault,
//            collapseSubroles: true
//        )
//    }
    
    private func timecodeStringFormat() -> Timecode.StringFormat {
        enableSubframes ? [.showSubFrames] : .default()
    }
}
