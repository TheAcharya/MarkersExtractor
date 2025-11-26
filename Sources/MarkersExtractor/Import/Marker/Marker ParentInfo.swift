//
//  Marker ParentInfo.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import DAWFileKit
import TimecodeKitCore
import SwiftExtensions

extension Marker {
    struct ParentInfo {
        var clipType: String
        var clipName: String
        var clipInTime: Timecode
        var clipOutTime: Timecode
        var clipKeywords: [String]
        
        var libraryName: String?
        var eventName: String?
        var projectName: String?
        
        // will be same as project name when project is present, otherwise timeline clip name
        var timelineName: String
        // project start, or clip start if no project
        var timelineStartTime: Timecode
    }
}

extension Marker.ParentInfo: Equatable { }

extension Marker.ParentInfo: Hashable { }

extension Marker.ParentInfo: Sendable { }

// MARK: - Properties

extension Marker.ParentInfo {
    func clipInTimeString(format: ExportMarkerTimeFormat) -> String {
        Self.timeString(from: clipInTime, format: format)
    }
    
    func clipOutTimeString(format: ExportMarkerTimeFormat) -> String {
        Self.timeString(from: clipOutTime, format: format)
    }
    
    func clipDurationTimeString(format: ExportMarkerTimeFormat) -> String {
        let dur = clipOutTime - clipInTime
        return Self.timeString(from: dur, format: format)
    }
    
    static func timeString(
        from timecode: Timecode,
        format: ExportMarkerTimeFormat
    ) -> String {
        switch format {
        case .timecode(let stringFormat):
            return timecode.stringValue(format: stringFormat)
        case .realTime(let stringFormat):
            // convert timecode to real time (wall time)
            return Time(seconds: timecode.realTimeValue)
                .stringValue(format: stringFormat)
        case .srt:
            return Time(seconds: timecode.realTimeValue)
                .srtEncodedString()
        }
    }
    
    func clipKeywordsFlat() -> String {
        clipKeywords.joined(separator: ",")
    }
    
    func clipKeywordsFormatted() -> (flat: String, array: [String]) {
        (flat: clipKeywordsFlat(), array: clipKeywords)
    }
}
