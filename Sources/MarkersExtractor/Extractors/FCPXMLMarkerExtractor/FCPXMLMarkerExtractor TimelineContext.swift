//
//  FCPXMLMarkerExtractor TimelineContext.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation
import SwiftTimecodeCore

extension FCPXMLMarkerExtractor {
    struct TimelineContext {
        let library: FinalCutPro.FCPXML.Library?
        let projectName: String?
        let timeline: FinalCutPro.FCPXML.AnyTimeline
        let timelineName: String
        let timelineStartTimecode: Timecode
    }
}

extension FCPXMLMarkerExtractor.TimelineContext: Equatable { }

extension FCPXMLMarkerExtractor.TimelineContext: Hashable { }

// Using @unchecked to allow use of non-Sendable DAWFileTools types,
// which should be safe since we only ever read and never write to them
extension FCPXMLMarkerExtractor.TimelineContext: @unchecked Sendable { }
