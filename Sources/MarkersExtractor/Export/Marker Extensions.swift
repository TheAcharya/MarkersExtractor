import Foundation
import OrderedCollections

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
    
    init(_ marker: Marker, imageFormat: MarkerImageFormat, isSingleFrame: Bool) {
        id = marker.id
        name = marker.name
        type = marker.type.rawValue
        checked = String(marker.checked)
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
            : "\(marker.idPathSafe).\(imageFormat)"
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
