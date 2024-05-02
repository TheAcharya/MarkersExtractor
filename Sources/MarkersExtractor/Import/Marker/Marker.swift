//
//  Marker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import DAWFileKit
import TimecodeKit
import OTCore

/// Raw FCP Marker data extracted from FCPXML.
///
/// - Note: This struct should mainly be an agnostic data repository and not assume anything about
/// its ultimate intended destination(s).
public struct Marker: Equatable, Hashable, Sendable {
    struct ParentInfo: Equatable, Hashable {
        var clipType: String
        var clipName: String
        var clipInTime: Timecode
        var clipOutTime: Timecode
        var clipKeywords: [String]
        var eventName: String
        var projectName: String
        var projectStartTime: Timecode
        var libraryName: String
        
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
                return Time(seconds: timecode.realTimeValue).stringValue(format: stringFormat)
            }
        }
        
        func clipKeywordsFlat() -> String {
            clipKeywords.joined(separator: ",")
        }
        
        func clipKeywordsFormatted() -> (flat: String, array: [String]) {
            (flat: clipKeywordsFlat(), array: clipKeywords)
        }
    }
    
    var type: InterpretedMarkerType
    var name: String
    var notes: String
    var roles: MarkerRoles
    var position: Timecode
    
    // TODO: This shouldn't be stored here. Should be refactored out to reference its parent with computed properties.
    /// Cached parent information.
    var parentInfo: ParentInfo
    
    struct Metadata: Equatable, Hashable {
        var reel: String
        var scene: String
        var take: String
    }
    
    /// Cached metadata.
    var metadata: Metadata
    
    /// Used only when uniquing marker IDs to avoid duplicate IDs.
    var idSuffix: String?
}

// MARK: Computed

extension Marker {
    func id(_ idMode: MarkerIDMode, tcStringFormat: Timecode.StringFormat) -> String {
        let baseID: String = {
            switch idMode {
            case .projectTimecode:
                return "\(parentInfo.projectName)_\(positionTimeString(format: .timecode(stringFormat: tcStringFormat)))"
            case .name:
                return name
            case .notes:
                return notes
            }
        }()
        return baseID + (idSuffix ?? "")
    }
    
    func id(pathSafe idMode: MarkerIDMode, tcStringFormat: Timecode.StringFormat) -> String {
        switch idMode {
        case .projectTimecode:
            return id(idMode, tcStringFormat: tcStringFormat)
                .replacingOccurrences(of: ";", with: "-") // used in drop-frame timecode
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: ".", with: "_") // when subframes are enabled
                .sanitizingPathComponent(for: nil, replacement: "-")
        case .name, .notes:
            return id(idMode, tcStringFormat: tcStringFormat)
                .replacingOccurrences(of: ":", with: "-")
                .sanitizingPathComponent(for: nil, replacement: "-")
        }
    }
    
    func frameRate() -> TimecodeFrameRate {
        position.frameRate
    }
    
    func subFramesBase() -> Timecode.SubFramesBase {
        position.subFramesBase
    }
    
    func upperLimit() -> Timecode.UpperLimit {
        position.upperLimit
    }
    
    func offsetFromProjectStart() -> Timecode {
        position - parentInfo.projectStartTime
    }
    
    func isChecked() -> Bool {
        switch type {
        case let .marker(.toDo(completed)):
            return completed
        default:
            return false
        }
    }
    
    /// - Parameters:
    ///   - format: Time display format.
    ///   - offsetToProjectStart: If true, time will be offset by project start time such that the timeline will be
    ///     considered as starting from zero.
    func positionTimeString(
        format: ExportMarkerTimeFormat,
        offsetToProjectStart: Bool = false
    ) -> String {
        let rectifiedPosition = offsetToProjectStart
            ? position - parentInfo.projectStartTime
            : position
        
        switch format {
        case .timecode(let stringFormat):
            return rectifiedPosition.stringValue(format: stringFormat)
        case .realTime(let stringFormat):
            // convert timecode to real time (wall time)
            return Time(seconds: rectifiedPosition.realTimeValue).stringValue(format: stringFormat)
        }
    }
}

extension Marker: Comparable {
    public static func < (lhs: Marker, rhs: Marker) -> Bool {
        lhs.position < rhs.position
    }
}
