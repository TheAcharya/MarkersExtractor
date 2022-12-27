import Foundation
import OrderedCollections

/// A marker with its contents prepared for CSV output.
struct CSVMarker {
    let id: String
    let name: String
    let type: String
    let checked: String
    let status: String
    let notes: String
    let position: String
    let clipName: String
    let clipDuration: String
    let role: String
    let eventName: String
    let projectName: String
    let libraryName: String
    let iconImage: String
    let imageFileName: String
    
    init(_ marker: Marker,
         idMode: MarkerIDMode,
         imageFormat: MarkerImageFormat,
         isSingleFrame: Bool
    ) {
        id = marker.id(idMode)
        name = marker.name
        type = marker.type.name
        checked = String(marker.isChecked)
        status = marker.status.rawValue
        notes = marker.notes
        position = marker.positionTimecodeString
        clipName = marker.parentInfo.clipName
        clipDuration = marker.parentInfo.clipDurationTimecodeString
        role = marker.role
        eventName = marker.parentInfo.eventName
        projectName = marker.parentInfo.projectName
        libraryName = marker.parentInfo.libraryName
        iconImage = marker.icon.fileName
        imageFileName = isSingleFrame
            ? "marker-placeholder.\(imageFormat)"
        : "\(marker.id(pathSafe: idMode)).\(imageFormat)"
    }
    
    func dictionaryRepresentation() -> OrderedDictionary<MarkersCSVHeader, String> {
        [
            .id: id,
            .name: name,
            .type: type,
            .checked: checked,
            .status: status,
            .notes: notes,
            .position: position,
            .clipName: clipName,
            .clipDuration: clipDuration,
            .role: role,
            .eventName: eventName,
            .projectName: projectName,
            .libraryName: libraryName,
            .iconImage: iconImage,
            .imageFileName: imageFileName
        ]
    }
}

extension CSVMarker {
    enum Status: String, CaseIterable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case done = "Done"
    }
}

extension Marker {
    fileprivate var isChecked: Bool {
        switch type {
        case .todo(let completed):
            return completed
        default:
            return false
        }
    }
    
    fileprivate var status: CSVMarker.Status {
        switch type {
        case .standard:
            return .notStarted
        case .todo(let completed):
            return completed ? .done : .inProgress
        case .chapter:
            return .notStarted
        }
    }
}

