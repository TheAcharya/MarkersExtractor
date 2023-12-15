//
//  MarkersExtractor Metadata.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation
import TimecodeKit

extension MarkersExtractor {
    /// Fetch the FCPXML project's frame rate, with fallbacks in case errors occur.
    func startTimecode(forProject project: FinalCutPro.FCPXML.Project) -> Timecode {
        if let tc = project.startTimecode() {
            logger.info(
                "Project start timecode: \(tc.stringValue(format: timecodeStringFormat)) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        } else if let frameRate = project.localTimecodeFrameRate() {
            let tc = FinalCutPro.formTimecode(at: frameRate)
            return tc
        } else {
            let tc = FinalCutPro.formTimecode(at: .fps30)
            logger.warning(
                "Could not determine project start timecode. Defaulting to \(tc.stringValue(format: timecodeStringFormat)) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        }
    }
    
    var timecodeStringFormat: Timecode.StringFormat {
        s.enableSubframes ? [.showSubFrames] : .default()
    }
}

extension MarkersExtractor {
    static let extractionScope: FinalCutPro.FCPXML.ExtractionScope = .mainTimeline
}
