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
    
    // MARK: - Public Instance Methods

    public func extractMarkers(
        preloadedProjects projects: [FinalCutPro.FCPXML.Project]? = nil
    ) async -> [Marker] {
        progress.completedUnitCount = 0
        progress.totalUnitCount = 1
        
        defer { progress.completedUnitCount = 1 }
        
        var fcpxmlMarkers: [Marker] = []

        let parsedFCPXML = FinalCutPro.FCPXML(fileContent: fcpxmlDoc)
        
        let library = parsedFCPXML.root.library
        
        let projects = projects ?? FinalCutPro.FCPXML(fileContent: fcpxmlDoc)
            .allProjects()
        
        for project in projects {
            guard let projectStartTime = project.startTimecode() else {
                logger.error(
                    "Could not determine start time for project \((project.name ?? "").quoted)."
                )
                return []
            }
            
            if markersSource.includesMarkers {
                fcpxmlMarkers += await markers(
                    in: project,
                    library: library,
                    projectStartTime: projectStartTime
                )
            }
            
            if markersSource.includesCaptions {
                fcpxmlMarkers += await captions(
                    in: project,
                    library: library,
                    projectStartTime: projectStartTime
                )
            }
        }
        
        // remove markers with excluded roles
        fcpxmlMarkers.removeAll(where: {
            $0.roles.contains(roleWithAnyNameIn: excludeRoles)
        })
        
        return fcpxmlMarkers
    }
    
    // MARK: - Private Methods

    private func markers(
        in project: FinalCutPro.FCPXML.Project,
        library: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
    ) async -> [Marker] {
        let extractedMarkers = await project.extract(
            preset: .markers,
            scope: MarkersExtractor.extractionScope(includeDisabled: includeDisabled)
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
    ) async -> [Marker] {
        let extractedCaptions = await project.extract(
            preset: .captions,
            scope: MarkersExtractor.extractionScope(includeDisabled: includeDisabled)
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
        _ extractedMarker: FinalCutPro.FCPXML.ExtractedMarker,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
    ) -> Marker? {
        let roles = getClipRoles(extractedMarker)
        
        guard let position = extractedMarker.value(forContext: .absoluteStartAsTimecode()),
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
            type: .marker(extractedMarker.configuration),
            name: extractedMarker.name,
            notes: extractedMarker.note ?? "",
            roles: roles,
            position: position,
            parentInfo: parentInfo
        )
    }
    
    private func convertCaption(
        _ extractedCaption: FinalCutPro.FCPXML.ExtractedCaption,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
    ) -> Marker? {
        let roles = getClipRoles(extractedCaption)
        
        let name = extractedCaption.name ?? ""
        
        guard let position = extractedCaption.timecode(),
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
            notes: extractedCaption.element.fcpNote ?? "",
            roles: roles,
            position: position,
            parentInfo: parentInfo
        )
    }
    
    private func parentInfo(
        from element: any FCPXMLExtractedModelElement,
        parentLibrary: FinalCutPro.FCPXML.Library?,
        projectStartTime: Timecode
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
            eventName: element.value(forContext: .ancestorEventName) ?? "",
            projectName: element.value(forContext: .ancestorProjectName) ?? "",
            projectStartTime: projectStartTime,
            libraryName: parentLibrary?.name ?? ""
        )
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
