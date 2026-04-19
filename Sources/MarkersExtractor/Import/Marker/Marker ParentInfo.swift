//
//  Marker ParentInfo.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import DAWFileTools
import SwiftExtensions
import SwiftTimecodeCore

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
        case let .timecode(stringFormat):
            timecode.stringValue(format: stringFormat)
        case let .realTime(stringFormat):
            // convert timecode to real time (wall time)
            Time(seconds: timecode.realTimeValue)
                .stringValue(format: stringFormat)
        case .srt:
            Time(seconds: timecode.realTimeValue)
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
