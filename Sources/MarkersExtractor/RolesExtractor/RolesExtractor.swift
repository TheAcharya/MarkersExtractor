//
//  RolesExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation
import OTCore

/// Returns all the roles used in a FCPXML document that are relevant to the main timeline.
///
/// Results will be formatted in the same manner as ``MarkersExtractor`` formats
/// roles for output manifest files.
///
/// Results will be sorted by type (video, audio, caption), then by name.
public final class RolesExtractor {
    public var fcpxml: FCPXMLFile
    
    public init(fcpxml: FCPXMLFile) {
        self.fcpxml = fcpxml
    }
    
    /// Returns all the roles used in the FCPXML document that are relevant to the main timeline.
    ///
    /// Results will be formatted in the same manner as ``MarkersExtractor`` formats
    /// roles for output manifest files.
    ///
    /// Results will be sorted by type (video, audio, caption), then by name.
    ///
    /// - Returns: A flat array of roles.
    public func extract() async throws -> [FinalCutPro.FCPXML.AnyRole] {
        let dawFile = try fcpxml.dawFile()
        guard let timeline = dawFile.allTimelines().first else { return [] }
        
        let timelineRoles = await timeline.extract(
            preset: .roles(roleTypes: .allCases),
            scope: .mainTimeline
        )
        
        let sorted = timelineRoles
            .map {
                FCPXMLMarkerExtractor.processExtractedRole(role: $0)
            }
        
        return sorted
    }
}
