import CoreMedia
import TimecodeKit

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
    
    var type: MarkerType
    var name: String
    var notes: String
    var role: String
    var status: MarkerStatus
    var checked: Bool
    var position: Timecode
    var nameMode: MarkerIDMode
    
    // TODO: This shouldn't be stored here. Should be refactored out to reference its parent with computed properties.
    /// Cached parent information.
    var parentInfo: ParentInfo
    
    var id: String {
        switch nameMode {
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
        case .todo:
            return checked ? .completed : .todo
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
