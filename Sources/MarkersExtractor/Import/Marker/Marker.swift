//
//  Marker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia
import TimecodeKit

/// Raw FCP Marker data extracted from FCPXML.
///
/// - Note: This struct should mainly be an agnostic data repository and not assume anything about
/// its ultimate intended destination(s).
public struct Marker: Equatable, Hashable {
    struct ParentInfo: Equatable, Hashable {
        var clipName: String
        var clipFilename: String
        var clipInTime: Timecode
        var clipOutTime: Timecode
        var eventName: String
        var projectName: String
        var libraryName: String
        
        var clipDurationTimecodeString: String {
            (clipOutTime - clipInTime).stringValue
        }
    }
    
    // raw metadata-related
    var type: MarkerType
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
    func id(_ idMode: MarkerIDMode) -> String {
        let baseID: String = {
            switch idMode {
            case .projectTimecode:
                return "\(parentInfo.projectName)_\(positionTimecodeString())"
            case .name:
                return name
            case .notes:
                return notes
            }
        }()
        return baseID + (idSuffix ?? "")
    }
    
    func id(pathSafe idMode: MarkerIDMode) -> String {
        // TODO: add better sanitation here that can deal with all illegal filename characters
        
        switch idMode {
        case .projectTimecode:
            return id(idMode)
                .replacingOccurrences(of: ";", with: "_") // used in drop-frame timecode
                .replacingOccurrences(of: ":", with: "_")
                .replacingOccurrences(of: ".", with: "_") // when subframes are enabled
        case .name, .notes:
            return id(idMode)
                .replacingOccurrences(of: ":", with: "_")
        }
    }
    
    func frameRate() -> TimecodeFrameRate {
        position.frameRate
    }
    
    func isChecked() -> Bool {
        switch type {
        case let .todo(completed):
            return completed
        default:
            return false
        }
    }
    
    func positionTimecodeString() -> String {
        position.stringValue
    }
    
    /// A marker is considered outside of its clip's bounds if its position is
    /// `<= clip exact start` or `>= clip exact end`.
    func isOutOfClipBounds() -> Bool {
        position <= parentInfo.clipInTime || position >= parentInfo.clipOutTime
    }
}

extension Marker: Comparable {
    public static func < (lhs: Marker, rhs: Marker) -> Bool {
        lhs.position < rhs.position
    }
}
