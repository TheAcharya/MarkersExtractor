import CoreMedia
import TimecodeKit

/// Raw FCP Marker data extracted from FCPXML.
///
/// - Note: This struct should mainly be an agnostic data repository and not assume anything about
/// its ultimate intended destination(s).
struct Marker: Equatable, Hashable {
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
    var role: String
    var position: Timecode
    
    // CSV-related
    var idMode: MarkerIDMode
    
    // TODO: This shouldn't be stored here. Should be refactored out to reference its parent with computed properties.
    /// Cached parent information.
    var parentInfo: ParentInfo
}

// MARK: Computed

extension Marker {
    var id: String {
        switch idMode {
        case .projectTimecode:
            return "\(parentInfo.projectName)_\(positionTimecodeString)"
        case .name:
            return name
        case .notes:
            return notes
        }
    }
    
    var idPathSafe: String {
        id
            .replacingOccurrences(of: ";", with: "_") // used in drop-frame timecode
            .replacingOccurrences(of: ":", with: "_")
    }
    
    var frameRate: TimecodeFrameRate {
        position.frameRate
    }
    
    var positionTimecodeString: String {
        position.stringValue
    }

    var icon: MarkerIcon {
        switch type {
        case .standard:
            return .standard
        case .todo(let completed):
            return completed ? .completed : .todo
        case .chapter:
            return .chapter
        }
    }
}

extension Marker: Comparable {
    static func < (lhs: Marker, rhs: Marker) -> Bool {
        lhs.position < rhs.position
    }
}
