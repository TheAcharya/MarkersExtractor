//
//  FCPXMLMarkerExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import DAWFileKit
import Foundation
import Logging
import TimecodeKit
import OTCore

class FCPXMLMarkerExtractor: NSObject, ProgressReporting {
    private let logger: Logger
    public let progress: Progress
    
    let fcpxmlDoc: XMLDocument
    let idNamingMode: MarkerIDMode
    let includeOutsideClipBoundaries: Bool
    let enableSubframes: Bool
    let markersSource: MarkersSource
    
    // MARK: - Init
    
    required init(
        fcpxml: XMLDocument,
        idNamingMode: MarkerIDMode,
        includeOutsideClipBoundaries: Bool,
        enableSubframes: Bool,
        markersSource: MarkersSource,
        logger: Logger? = nil
    ) {
        self.logger = logger ?? Logger(label: "\(Self.self)")
        progress = Progress()
        
        fcpxmlDoc = fcpxml
        self.idNamingMode = idNamingMode
        self.includeOutsideClipBoundaries = includeOutsideClipBoundaries
        self.enableSubframes = enableSubframes
        self.markersSource = markersSource
    }
    
    required convenience init(
        fcpxml: URL,
        idNamingMode: MarkerIDMode,
        includeOutsideClipBoundaries: Bool,
        enableSubframes: Bool,
        markersSource: MarkersSource,
        logger: Logger? = nil
    ) throws {
        let xml = try XMLDocument(contentsOf: fcpxml)
        self.init(
            fcpxml: xml,
            idNamingMode: idNamingMode,
            includeOutsideClipBoundaries: includeOutsideClipBoundaries,
            enableSubframes: enableSubframes,
            markersSource: markersSource,
            logger: logger
        )
    }
    
    required convenience init(
        fcpxml: inout FCPXMLFile,
        idNamingMode: MarkerIDMode,
        includeOutsideClipBoundaries: Bool,
        enableSubframes: Bool,
        markersSource: MarkersSource,
        logger: Logger? = nil
    ) throws {
        let xml = try fcpxml.xmlDocument()
        self.init(
            fcpxml: xml,
            idNamingMode: idNamingMode,
            includeOutsideClipBoundaries: includeOutsideClipBoundaries,
            enableSubframes: enableSubframes,
            markersSource: markersSource,
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
        
        for project in parsedFCPXML.allProjects(context: MarkersExtractor.elementContext) {
            guard let projectStartTime = project.startTimecode else {
                logger.error(
                    "Could not determine start time for project \((project.name ?? "").quoted)."
                )
                return []
            }
            
            if markersSource.includesMarkers {
                fcpxmlMarkers += markers(
                    in: project,
                    library: library,
                    projectStartTime: projectStartTime
                )
            }
            
            if markersSource.includesCaptions {
                fcpxmlMarkers += captions(
                    in: project,
                    library: library,
                    projectStartTime: projectStartTime
                )
            }
        }
        
        // apply out-of-bounds filter
        if !includeOutsideClipBoundaries {
            let (kept, omitted): (kept: [Marker], omitted: [Marker]) = fcpxmlMarkers
                .reduce(into: ([], [])) { base, markerOrCaption in
                    switch markerOrCaption.type {
                    case .marker:
                        markerOrCaption.isOutOfBounds
                            ? base.omitted.append(markerOrCaption)
                            : base.kept.append(markerOrCaption)
                    case .caption:
                        // always allow captions since they are not attached to clips,
                        // but are timeline-global elements
                        base.kept.append(markerOrCaption)
                    }
                    
                }
            
            // remove out-of-bounds markers from output
            fcpxmlMarkers = kept
            
            // emit log messages for out-of-bounds markers
            omitted.forEach { marker in
                let mn = marker.name.quoted
                let pos = marker.position
                // let clipName = marker.parentInfo.clipName.quoted
                // let inTime = marker.parentInfo.clipInTime
                // let outTime = marker.parentInfo.clipOutTime
                logger.notice(
                    "\(marker.type.fullName) \(mn) at \(pos) is not visible on the main timeline and will be omitted."
                )
            }
        }
        
        return fcpxmlMarkers
    }
    
    // MARK: - Private Methods

    private func markers(
        in project: FinalCutPro.FCPXML.Project,
        library: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
    ) -> [Marker] {
        let extractedMarkers = project.extractElements(
            preset: .markers,
            settings: MarkersExtractor.extractSettings
        )
        
        return extractedMarkers.compactMap {
            convertMarker(
                $0,
                parentLibrary: library,
                projectStartTime: projectStartTime
            )
        }
    }
    
    private func captions(
        in project: FinalCutPro.FCPXML.Project,
        library: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
    ) -> [Marker] {
        let extractedCaptions = project.extractElements(
            preset: .captions,
            settings: MarkersExtractor.extractSettings
        )
        
        return extractedCaptions.compactMap {
            convertCaption(
                $0,
                parentLibrary: library,
                projectStartTime: projectStartTime
            )
        }
    }
    
    private func convertMarker(
        _ extractedMarker: FinalCutPro.FCPXML.Marker,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
    ) -> Marker? {
        let roles = getClipRoles(extractedMarker.asAnyStoryElement())
        
        guard let position = extractedMarker.context[.absoluteStart],
              let parentInfo = parentInfo(
                  from: extractedMarker,
                  parentLibrary: parentLibrary,
                  projectStartTime: projectStartTime
              )
        else {
            logger.error("Error converting marker: \(extractedMarker.name.quoted).")
            return nil
        }
        
        return Marker(
            type: .marker(extractedMarker.metaData),
            name: extractedMarker.name,
            notes: extractedMarker.note ?? "",
            roles: roles,
            position: position,
            isOutOfBounds: extractedMarker.isOutOfBounds,
            parentInfo: parentInfo
        )
    }
    
    private func convertCaption(
        _ extractedCaption: FinalCutPro.FCPXML.Caption,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
    ) -> Marker? {
        let roles = getClipRoles(extractedCaption.asAnyStoryElement())
        
        let name = extractedCaption.name ?? ""
        
        guard let position = extractedCaption.context[.absoluteStart],
              let parentInfo = parentInfo(
                  from: extractedCaption,
                  parentLibrary: parentLibrary,
                  projectStartTime: projectStartTime
              )
        else {
            logger.error("Error converting caption: \(name.quoted).")
            return nil
        }
        
        return Marker(
            type: .caption,
            name: name,
            notes: extractedCaption.note ?? "",
            roles: roles,
            position: position,
            isOutOfBounds: extractedCaption.isOutOfBounds,
            parentInfo: parentInfo
        )
    }
    
    private func parentInfo(
        from element: some FCPXMLElement,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
    ) -> Marker.ParentInfo? {
        guard let clipInTime = element.context[.parentAbsoluteStart],
              let clipDuration = element.context[.parentDuration],
              let clipOutTime = try? clipInTime.adding(clipDuration, by: .wrapping)
        else { return nil }
        
        return Marker.ParentInfo(
            clipType: element.context[.parentType]?.name ?? "",
            clipName: element.context[.parentName] ?? "",
            clipInTime: clipInTime,
            clipOutTime: clipOutTime,
            eventName: element.context[.ancestorEventName] ?? "",
            projectName: element.context[.ancestorProjectName] ?? "",
            projectStartTime: projectStartTime,
            libraryName: parentLibrary?.name ?? ""
        )
    }
    
    func getClipRoles(_ element: FinalCutPro.FCPXML.AnyStoryElement) -> MarkerRoles {
        var markerRoles = MarkerRoles()
        
        // marker doesn't contain role(s) so look to ancestors
        let roles = element.context[.inheritedRoles] ?? []
        roles.forEach { interpolatedRole in
            var isRoleDefault = false
            
            func handle(role: FinalCutPro.FCPXML.AnyRole) {
                switch role {
                case let .audio(audioRole):
                    markerRoles.isAudioDefault = isRoleDefault
                    if !audioRole.rawValue.isEmpty {
                        if markerRoles.audio == nil { markerRoles.audio = [] }
                        markerRoles.audio?.append(audioRole)
                    }
                    
                case let .video(videoRole):
                    markerRoles.isVideoDefault = isRoleDefault
                    if !videoRole.rawValue.isEmpty { markerRoles.video = videoRole }
                    
                case let .caption(captionRole):
                    markerRoles.isCaptionDefault = isRoleDefault
                    if !captionRole.rawValue.isEmpty { markerRoles.caption = captionRole }
                }
            }
            
            switch interpolatedRole {
            case let .assigned(role), let .inherited(role):
                isRoleDefault = false
                handle(role: role)
                
            case let .defaulted(role):
                isRoleDefault = true
                handle(role: role)
            }
        }
        
        // collapse subroles that are redundant
        markerRoles.collapseSubroles()
        
        // remove any roles with empty strings
        markerRoles.removeEmptyStrings()
        
        // FCP often writes built-in roles as lowercase strings
        // (ie: "dialogue" or "dialogue.dialogue-1")
        // so we will explicitly title-case these if encountered, so as to match
        // FCP's title-cased display of these roles (ie: "Dialogue")
        markerRoles.titleCaseBuiltInRoles()
        
        return markerRoles
    }
    
    private func timecodeStringFormat() -> Timecode.StringFormat {
        enableSubframes ? [.showSubFrames] : .default()
    }
}
