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
            excludeTypes: [],
            auditionMask: .activeAudition
        )
        let extractedMarkers = event.extractMarkers(settings: settings, ancestorsOfParent: [])
        
        return extractedMarkers.compactMap {
            convertMarker(
                $0,
                parentLibrary: library
            )
        }
    }
    
    private func convertMarker(
        _ extractedMarker: FinalCutPro.FCPXML.Marker,
        parentLibrary: FinalCutPro.FCPXML.Library?
    ) -> Marker? {
        let roles = getClipRoles(extractedMarker)
        
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
            roles: roles,
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
    
    internal func getClipRoles(_ marker: FinalCutPro.FCPXML.Marker) -> MarkerRoles {
        var markerRoles = MarkerRoles()
        
        // marker doesn't contain role(s) so look to ancestors
        let roles = marker.context[.inheritedRoles] ?? []
        roles.forEach { interpolatedRole in
            var isRoleDefault: Bool = false
            
            func handle(role: FinalCutPro.FCPXML.Role) {
                switch role {
                case let .audio(roleString):
                    markerRoles.isAudioDefault = isRoleDefault
                    markerRoles.audio = roleString
                    
                case let .video(roleString):
                    markerRoles.isVideoDefault = isRoleDefault
                    markerRoles.video = roleString
                    
                case .caption(_):
                    // TODO: assign to video role may not be right?
                    // technically captions use their own auto-generated roles that users won't care
                    // about. and it doesn't seem right to inherit the role from the clip the caption is
                    // anchored to. if we convert captions to markers maybe it then makes sense to
                    // inherit role from the clip where the caption is anchored.
                    
                    break
                    // markerRoles.video = roleString
                }
            }
            
            switch interpolatedRole {
            case let .assigned(role):
                isRoleDefault = false
                handle(role: role)
                
            case let .defaulted(role):
                isRoleDefault = true
                handle(role: role)
            }
        }
        
        return markerRoles.collapsedSubroles()
    }
    
    private func timecodeStringFormat() -> Timecode.StringFormat {
        enableSubframes ? [.showSubFrames] : .default()
    }
}
