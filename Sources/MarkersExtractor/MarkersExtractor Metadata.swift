//
//  MarkersExtractor Metadata.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation
import TimecodeKitCore

extension MarkersExtractor {
    var timecodeStringFormat: Timecode.StringFormat {
        settings.enableSubframes ? [.showSubFrames] : .default()
    }
}

extension MarkersExtractor {
    static func extractionScope(includeDisabled: Bool) -> FinalCutPro.FCPXML.ExtractionScope {
        var scope: FinalCutPro.FCPXML.ExtractionScope = .mainTimeline
        scope.includeDisabled = includeDisabled
        
        return scope
    }
}
