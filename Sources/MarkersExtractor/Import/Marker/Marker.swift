//
//  Marker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import DAWFileKit
import TimecodeKit

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
        var eventName: String
        var projectName: String
        var projectStartTime: Timecode
        var libraryName: String
        
        func clipDurationTimecodeString(format: Timecode.StringFormat) -> String {
            (clipOutTime - clipInTime).stringValue(format: format)
        }
    }
    
    // raw metadata-related
    var type: InterpretedMarkerType
    var name: String
    var notes: String
    var roles: MarkerRoles
    var position: Timecode
    
    // TODO: This shouldn't be stored here. Should be refactored out to reference its parent with computed properties.
    /// Cached parent information.
    var parentInfo: ParentInfo
    
    /// Used only when uniquing marker IDs to avoid duplicate IDs.
    var idSuffix: String?
}

// MARK: Computed

extension Marker {
    func id(_ idMode: MarkerIDMode, tcStringFormat: Timecode.StringFormat) -> String {
        let baseID: String = {
            switch idMode {
            case .projectTimecode:
                return "\(parentInfo.projectName)_\(positionTimecodeString(format: tcStringFormat))"
            case .name:
                return name
            case .notes:
                return notes
            }
        }()
        return baseID + (idSuffix ?? "")
    }
    
    func id(pathSafe idMode: MarkerIDMode, tcStringFormat: Timecode.StringFormat) -> String {
        // TODO: add better sanitation here that can deal with all illegal filename characters
        
        switch idMode {
        case .projectTimecode:
            return id(idMode, tcStringFormat: tcStringFormat)
                .replacingOccurrences(of: ";", with: "_") // used in drop-frame timecode
                .replacingOccurrences(of: ":", with: "_")
                .replacingOccurrences(of: ".", with: "_") // when subframes are enabled
        case .name, .notes:
            return id(idMode, tcStringFormat: tcStringFormat)
                .replacingOccurrences(of: ":", with: "_")
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
    
    func positionTimecodeString(format: Timecode.StringFormat) -> String {
        position.stringValue(format: format)
    }
    
    /// A marker is considered outside of its clip's bounds if its position is
    /// `< clip exact start` or `> clip exact end`.
    func isOutOfClipBounds() -> Bool {
        position < parentInfo.clipInTime || position > parentInfo.clipOutTime
    }
}

extension Marker: Comparable {
    public static func < (lhs: Marker, rhs: Marker) -> Bool {
        lhs.position < rhs.position
    }
}
