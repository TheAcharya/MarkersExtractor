//
//  FCPXMLMarkerExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import DAWFileKit
import Foundation
import Logging
import TimecodeKitCore
import OTCore

class FCPXMLMarkerExtractor {
    private let logger: Logger
    let progress: Progress
    
    let fcpxmlDoc: XMLDocument
    let idNamingMode: MarkerIDMode
    let enableSubframes: Bool
    let markersSource: MarkersSource
    let excludeRoles: Set<String>
    let includeDisabled: Bool
    
    // MARK: - Init
    
    required init(
        fcpxml: XMLDocument,
        idNamingMode: MarkerIDMode,
        enableSubframes: Bool,
        markersSource: MarkersSource,
        excludeRoles: Set<String>,
        includeDisabled: Bool,
        logger: Logger? = nil
    ) {
        self.logger = logger ?? Logger(label: "\(Self.self)")
        progress = Progress()
        
        fcpxmlDoc = fcpxml
        self.idNamingMode = idNamingMode
        self.enableSubframes = enableSubframes
        self.markersSource = markersSource
        self.excludeRoles = excludeRoles
        self.includeDisabled = includeDisabled
    }
    
    required convenience init(
        fcpxml: URL,
        idNamingMode: MarkerIDMode,
        enableSubframes: Bool,
        markersSource: MarkersSource,
        excludeRoles: Set<String>,
        includeDisabled: Bool,
        logger: Logger? = nil
    ) throws {
        let xml = try XMLDocument(contentsOf: fcpxml)
        self.init(
            fcpxml: xml,
            idNamingMode: idNamingMode,
            enableSubframes: enableSubframes,
            markersSource: markersSource,
            excludeRoles: excludeRoles,
            includeDisabled: includeDisabled,
            logger: logger
        )
    }
    
    required convenience init(
        fcpxml: inout FCPXMLFile,
        idNamingMode: MarkerIDMode,
        enableSubframes: Bool,
        markersSource: MarkersSource,
        excludeRoles: Set<String>,
        includeDisabled: Bool,
        logger: Logger? = nil
    ) throws {
        let xml = try fcpxml.xmlDocument()
        self.init(
            fcpxml: xml,
            idNamingMode: idNamingMode,
            enableSubframes: enableSubframes,
            markersSource: markersSource,
            excludeRoles: excludeRoles,
            includeDisabled: includeDisabled,
            logger: logger
        )
    }
}

// MARK: - Public Methods

extension FCPXMLMarkerExtractor {
    struct TimelineContext {
        let library: FinalCutPro.FCPXML.Library?
        let projectName: String?
        let timeline: FinalCutPro.FCPXML.AnyTimeline
        let timelineName: String
        let timelineStartTimecode: Timecode
    }
    
    /// Returns the first timeline found in the FCPXML as well as contextual metadata.
    func extractTimelineContext(
        defaultTimelineName: String
    ) -> TimelineContext? {
        let parsedFCPXML = FinalCutPro.FCPXML(fileContent: fcpxmlDoc)
        
        let library = parsedFCPXML.root.library
        
        // prioritize a project if one exists, otherwise use clips
        guard let timeline = parsedFCPXML.allTimelines().first else {
            logger.info(
                "No timelines (projects or clips) could be found in the FCPXML."
            )
            return nil
        }
        
        // project element may or may not exist.
        let parentProject = timeline.element
            .ancestorElements(includingSelf: false)
            .first(whereFCPElement: .project)
        
        let projectName = parentProject?.name
        
        // the timeline always needs a name, whether it's a project or a clip.
        // we prefer the project name if a project exists.
        // this should also not be an empty string.
        let timelineName = projectName
        ?? timeline.timelineName
        ?? defaultTimelineName
        
        // extract from origin element
        let timelineStartTimecode = startTimecode(for: timeline)
        
        return TimelineContext(
            library: library,
            projectName: projectName,
            timeline: timeline,
            timelineName: timelineName,
            timelineStartTimecode: timelineStartTimecode
        )
    }
    
    /// Fetch the FCPXML timeline's frame rate, with fallbacks in case errors occur.
    func startTimecode(for timeline: FinalCutPro.FCPXML.AnyTimeline) -> Timecode {
        if let tc = timeline.timelineStartAsTimecode() {
            logger.info(
                "Timeline start timecode: \(tc.stringValue()) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        } else if let frameRate = timeline.localTimecodeFrameRate() {
            let tc = FinalCutPro.formTimecode(at: frameRate)
            return tc
        } else {
            let tc = FinalCutPro.formTimecode(at: .fps30)
            logger.warning(
                "Could not determine timeline start timecode. Defaulting to \(tc.stringValue()) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        }
    }
    
    func extractMarkers(
        context: TimelineContext
    ) async -> [Marker] {
        progress.completedUnitCount = 0
        progress.totalUnitCount = 1
        
        defer { progress.completedUnitCount = 1 }
        
        var fcpxmlMarkers: [Marker] = []
        
        if markersSource.includesMarkers {
            fcpxmlMarkers += await markers(
                in: context.timeline,
                library: context.library,
                timelineName: context.timelineName,
                timelineStartTimecode: context.timelineStartTimecode
            )
        }
        
        if markersSource.includesCaptions {
            fcpxmlMarkers += await captions(
                in: context.timeline,
                library: context.library,
                timelineName: context.timelineName,
                timelineStartTimecode: context.timelineStartTimecode
            )
        }
        
        // remove markers with excluded roles
        fcpxmlMarkers.removeAll(where: {
            $0.roles.contains(roleWithAnyNameIn: excludeRoles)
        })
        
        return fcpxmlMarkers
    }
}

// MARK: - Private Methods

extension FCPXMLMarkerExtractor {
    private func markers(
        in timeline: FinalCutPro.FCPXML.AnyTimeline,
        library: FinalCutPro.FCPXML.Library?,
        timelineName: String,
        timelineStartTimecode: Timecode
    ) async -> [Marker] {
        let extractedMarkers = await timeline.extract(
            preset: .markers,
            scope: MarkersExtractor.extractionScope(includeDisabled: includeDisabled)
        )
        
        return extractedMarkers.compactMap {
            convertMarker(
                $0,
                parentLibrary: library,
                timelineName: timelineName,
                timelineStartTime: timelineStartTimecode
            )
        }
    }
    
    private func captions(
        in timeline: FinalCutPro.FCPXML.AnyTimeline,
        library: FinalCutPro.FCPXML.Library?,
        timelineName: String,
        timelineStartTimecode: Timecode
    ) async -> [Marker] {
        let extractedCaptions = await timeline.extract(
            preset: .captions,
            scope: MarkersExtractor.extractionScope(includeDisabled: includeDisabled)
        )
        
        return extractedCaptions.compactMap {
            convertCaption(
                $0,
                parentLibrary: library,
                timelineName: timelineName,
                timelineStartTime: timelineStartTimecode
            )
        }
    }
    
    private func convertMarker(
        _ extractedMarker: FinalCutPro.FCPXML.ExtractedMarker,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        timelineName: String,
        timelineStartTime: Timecode
    ) -> Marker? {
        let roles = getClipRoles(extractedMarker)
        
        guard let position = extractedMarker.value(forContext: .absoluteStartAsTimecode()),
              let parentInfo = parentInfo(
                  from: extractedMarker,
                  parentLibrary: parentLibrary, 
                  timelineName: timelineName,
                  timelineStartTime: timelineStartTime
              )
        else {
            logger.error("Error converting marker: \(extractedMarker.name.quoted).")
            return nil
        }
        
        let markerMetadata = metadata(for: extractedMarker)
        
        let xmlPath = extractedMarker.element.xPath ?? ""
        
        return Marker(
            type: .marker(extractedMarker.configuration),
            name: extractedMarker.name,
            notes: extractedMarker.note ?? "",
            roles: roles,
            position: position,
            parentInfo: parentInfo, 
            metadata: markerMetadata,
            xmlPath: xmlPath
        )
    }
    
    private func convertCaption(
        _ extractedCaption: FinalCutPro.FCPXML.ExtractedCaption,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        timelineName: String,
        timelineStartTime: Timecode
    ) -> Marker? {
        let roles = getClipRoles(extractedCaption)
        
        let name = extractedCaption.name ?? ""
        
        guard let position = extractedCaption.timecode(),
              let parentInfo = parentInfo(
                  from: extractedCaption,
                  parentLibrary: parentLibrary, 
                  timelineName: timelineName,
                  timelineStartTime: timelineStartTime
              )
        else {
            logger.error("Error converting caption: \(name.quoted).")
            return nil
        }
        
        let markerMetadata = metadata(for: extractedCaption)
        
        let xmlPath = extractedCaption.element.xPath ?? ""
        
        return Marker(
            type: .caption,
            name: name,
            notes: extractedCaption.element.fcpNote ?? "",
            roles: roles,
            position: position,
            parentInfo: parentInfo, 
            metadata: markerMetadata,
            xmlPath: xmlPath
        )
    }
    
    private func parentInfo(
        from element: any FCPXMLExtractedModelElement,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        timelineName: String,
        timelineStartTime: Timecode
    ) -> Marker.ParentInfo? {
        guard let clipInTime = element.value(forContext: .parentAbsoluteStartAsTimecode()),
              // let clipDuration = element.value(forContext: .parentDurationAsTimecode()),
              let clipOutTime = element.value(forContext: .parentAbsoluteEndAsTimecode())
        else { return nil }
        
        return Marker.ParentInfo(
            clipType: element.value(forContext: .parentType)?.name ?? "",
            clipName: element.value(forContext: .parentName) ?? "",
            clipInTime: clipInTime,
            clipOutTime: clipOutTime,
            clipKeywords: element.value(forContext: .keywordsFlat(constrainToKeywordRanges: true)),
            libraryName: parentLibrary?.name ?? "",
            eventName: element.value(forContext: .ancestorEventName) ?? "",
            projectName: element.value(forContext: .ancestorProjectName),
            timelineName: timelineName,
            timelineStartTime: timelineStartTime
        )
    }
    
    private func metadata(
        for extractedMarker: FinalCutPro.FCPXML.ExtractedMarker
    ) -> Marker.Metadata {
        let rawMetadata = extractedMarker.value(forContext: .metadata)
        
        return convertMetadata(rawMetadata: rawMetadata)
    }
    
    private func metadata(
        for extractedCaption: FinalCutPro.FCPXML.ExtractedCaption
    ) -> Marker.Metadata {
        let rawMetadata = extractedCaption.value(forContext: .metadata)
        
        return convertMetadata(rawMetadata: rawMetadata)
    }
    
    private func convertMetadata(
        rawMetadata: [FinalCutPro.FCPXML.Metadata.Metadatum]
    ) -> Marker.Metadata {
        // map metadata key/value pairs to a dictionary for easy access
        let metadataDict: [FinalCutPro.FCPXML.Metadata.Key: String] = rawMetadata
            .compactMapDictionary { element in
                guard let key = element.key else { return nil }
                let value = element.value ?? element.valueArray?.joined(separator: ",") ?? ""
                return (key, value)
            }
        
        let markerMetadata = Marker.Metadata(
            reel: metadataDict[.reel] ?? "",
            scene: metadataDict[.scene] ?? "",
            take: metadataDict[.take] ?? ""
        )
        
        return markerMetadata
    }
    
    func getClipRoles(_ element: any FCPXMLExtractedModelElement) -> MarkerRoles {
        var markerRoles = MarkerRoles()
        
        // marker doesn't contain role(s) so look to ancestors
        let roles = element.value(forContext: .inheritedRoles)
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
        
        // process markers
        markerRoles.process()
        
        return markerRoles
    }
    
    private func timecodeStringFormat() -> Timecode.StringFormat {
        enableSubframes ? [.showSubFrames] : .default()
    }
}

extension FCPXMLMarkerExtractor {
    static func processExtractedRole<Role: FCPXMLRole>(role: Role) -> Role {
        role
            // collapse subroles that are redundant
            .collapsingSubRole()
        
            // FCP often writes built-in roles as lowercase strings
            // (ie: "dialogue" or "dialogue.dialogue-1")
            // so we will explicitly title-case these if encountered, so as to match
            // FCP's title-cased display of these roles (ie: "Dialogue")
            .titleCasedDefaultRole(derivedOnly: true)
    }
}
