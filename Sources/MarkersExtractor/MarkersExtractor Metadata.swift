//
//  MarkersExtractor Metadata.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation
import TimecodeKit

extension MarkersExtractor {
    /// Fetch the FCPXML timeline's frame rate, with fallbacks in case errors occur.
    func startTimecode(for timeline: FinalCutPro.FCPXML.AnyTimeline) -> Timecode {
        if let tc = timeline.timelineStartAsTimecode() {
            logger.info(
                "Timeline start timecode: \(tc.stringValue(format: timecodeStringFormat)) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        } else if let frameRate = timeline.localTimecodeFrameRate() {
            let tc = FinalCutPro.formTimecode(at: frameRate)
            return tc
        } else {
            let tc = FinalCutPro.formTimecode(at: .fps30)
            logger.warning(
                "Could not determine timeline start timecode. Defaulting to \(tc.stringValue(format: timecodeStringFormat)) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        }
    }
    
    var timecodeStringFormat: Timecode.StringFormat {
        s.enableSubframes ? [.showSubFrames] : .default()
    }
}

extension MarkersExtractor {
    static func extractionScope(includeDisabled: Bool) -> FinalCutPro.FCPXML.ExtractionScope {
        var scope: FinalCutPro.FCPXML.ExtractionScope = .mainTimeline
        scope.includeDisabled = includeDisabled
        
        return scope
    }
}
