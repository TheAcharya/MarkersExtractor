import CoreMedia

struct Marker {
    var type: MarkerType
    var name: String
    var notes: String
    var role: String
    var status: MarkerStatus
    var checked: Bool
    var position: CMTime
    var fps: CMTime
    var parentClipName: String
    var parentClipDuration: CMTime
    var parentEventName: String
    var parentProjectName: String
    var parentLibraryName: String
    var nameMode: MarkerIDMode

    var id: String {
        switch nameMode {
        case .projectTimecode:
            return "\(parentProjectName)_\(timecode)"
        case .name:
            return name
        case .notes:
            return notes
        }
    }

    var idPathSafe: String {
        id.replacingOccurrences(of: ":", with: "_")
    }

    var timecode: String {
        position.timeAsTimecode(usingFrameDuration: fps, dropFrame: false).timecodeString
    }

    var parentClipDurationTimecode: String {
        parentClipDuration.timeAsTimecode(usingFrameDuration: fps, dropFrame: false).timecodeString
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
