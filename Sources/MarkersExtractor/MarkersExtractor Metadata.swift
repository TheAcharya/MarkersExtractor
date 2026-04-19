//
//  MarkersExtractor Metadata.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation
import SwiftTimecodeCore

extension MarkersExtractor {
    var timecodeStringFormat: Timecode.StringFormat {
        settings.enableSubframes ? [.showSubFrames] : .default()
    }
}

extension MarkersExtractor {
    static func extractionScope(includeDisabled: Bool) -> FCPXML.ExtractionScope {
        var scope: FCPXML.ExtractionScope = .mainTimeline
        scope.includeDisabled = includeDisabled

        return scope
    }
}
