//
//  Marker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import DAWFileKit
import TimecodeKitCore
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
        
        var libraryName: String?
        var eventName: String?
        var projectName: String?
        
        var timelineName: String // will be same as project name when project is present, otherwise timeline clip name
        var timelineStartTime: Timecode // project start, or clip start if no project
        
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
    
    /// XML XPath for back-reference allowing editing of the FCPXML directly.
    var xmlPath: String
}

// MARK: Computed

extension Marker {
    func id(_ idMode: MarkerIDMode, tcStringFormat: Timecode.StringFormat) -> String {
        let baseID: String = {
            switch idMode {
            case .timelineNameAndTimecode:
                return "\(parentInfo.timelineName)_\(positionTimeString(format: .timecode(stringFormat: tcStringFormat)))"
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
        case .timelineNameAndTimecode:
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
    
    func positionOffsetFromTimelineStart() -> Timecode {
        position - parentInfo.timelineStartTime
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
    ///   - offsetToTimelineStart: If true, time will be offset by timeline start time such that the timeline will be
    ///     considered as starting from zero.
    func positionTimeString(
        format: ExportMarkerTimeFormat,
        offsetToTimelineStart: Bool = false
    ) -> String {
        let rectifiedPosition = positionTimecode(offsetToTimelineStart: offsetToTimelineStart)
        
        switch format {
        case .timecode(let stringFormat):
            return rectifiedPosition.stringValue(format: stringFormat)
        case .realTime(let stringFormat):
            // convert timecode to real time (wall time)
            return Time(seconds: rectifiedPosition.realTimeValue).stringValue(format: stringFormat)
        }
    }
    
    func positionTimecode(offsetToTimelineStart: Bool = false) -> Timecode {
        offsetToTimelineStart
            ? position - parentInfo.timelineStartTime
            : position
    }
    
    /// The timecode to use for thumbnail image extraction.
    /// This is usually the same as marker position, except for certain cases such as a chapter
    /// marker which may incorporate its poster offset.
    ///
    /// - Parameters:
    ///   - useChapterMarkerPosterOffset: For chapter markers, use the poster offset.
    ///   - offsetToTimelineStart: If true, time will be offset by timeline start time such that the timeline will be
    ///     considered as starting from zero.
    func imageTimecode(
        useChapterMarkerPosterOffset: Bool,
        offsetToTimelineStart: Bool = false
    ) -> Timecode {
        let rectifiedPosition = positionTimecode(offsetToTimelineStart: offsetToTimelineStart)
        
        switch type {
        case .marker(.chapter(let posterOffset)):
            if useChapterMarkerPosterOffset {
                return (try? position.adding(.rational(posterOffset))) ?? rectifiedPosition
            } else {
                return rectifiedPosition
            }
        default:
            return rectifiedPosition
        }
    }
}

extension Marker: Comparable {
    public static func < (lhs: Marker, rhs: Marker) -> Bool {
        lhs.position < rhs.position
    }
}

extension Marker: Identifiable {
    public var id: Self { self }
}
