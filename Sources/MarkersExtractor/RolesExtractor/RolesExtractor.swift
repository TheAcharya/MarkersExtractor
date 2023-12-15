//
//  RolesExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import DAWFileKit
import OTCore

/// Returns all the roles used in a FCPXML document that are relevant to the main project
/// timeline.
///
/// Results will be sorted by type (video, audio, caption), then by name.
public final class RolesExtractor {
    public var fcpxml: FCPXMLFile
    
    public init(fcpxml: FCPXMLFile) {
        self.fcpxml = fcpxml
    }
    
    /// Returns all the roles used in the FCPXML document that are relevant to the main project
    /// timeline.
    ///
    /// Results will be sorted by type (video, audio, caption), then by name.
    ///
    /// - Returns: A flat array of roles.
    public func extract() async throws -> [FinalCutPro.FCPXML.AnyRole] {
        let dawFile = try fcpxml.dawFile()
        let projects = dawFile.allProjects()
        
        let projectsRoles = await withOrderedTaskGroup(sequence: projects) { element in
            await element.extract(
                preset: .roles(roleTypes: .allCases),
                scope: .mainTimeline
            )
        }
        
        let sorted = projectsRoles
            .flatMap { $0 }
        
        return sorted
    }
}
