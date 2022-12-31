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
        var clipDuration: Timecode
        var eventName: String
        var projectName: String
        var libraryName: String
        
        var clipDurationTimecodeString: String {
            clipDuration.stringValue
        }
    }
    
    // raw metadata-related
    var type: MarkerType
    var name: String
    var notes: String
    var roles: [MarkerRole] // TODO: is more than one role possible?
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
                return "\(parentInfo.projectName)_\(positionTimecodeString)"
            case .name:
                return name
            case .notes:
                return notes
            }
        }()
        return baseID + (idSuffix ?? "")
    }
    
    func id(pathSafe idMode: MarkerIDMode) -> String {
        id(idMode)
            .replacingOccurrences(of: ";", with: "_") // used in drop-frame timecode
            .replacingOccurrences(of: ":", with: "_")
    }
    
    var frameRate: TimecodeFrameRate {
        position.frameRate
    }
    
    var positionTimecodeString: String {
        position.stringValue
    }
}

extension Marker: Comparable {
    public static func < (lhs: Marker, rhs: Marker) -> Bool {
        lhs.position < rhs.position
    }
}
