import Foundation
import OrderedCollections

extension CSVExportProfile {
    /// A marker with its contents prepared for CSV output.
    public struct PreparedMarker: ExportMarker {
        public let id: String
        public let name: String
        public let type: String
        public let checked: String
        public let status: String
        public let notes: String
        public let position: String
        public let clipName: String
        public let clipDuration: String
        public let audioRoles: String
        public let videoRoles: String
        public let eventName: String
        public let projectName: String
        public let libraryName: String
        public let iconImage: String
        public let imageFileName: String
        
        public init(_ marker: Marker,
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
            videoRoles = marker.roles.filter(\.isVideo).map { $0.stringValue }.joined(separator: ", ")
            audioRoles = marker.roles.filter(\.isAudio).map { $0.stringValue }.joined(separator: ", ")
            eventName = marker.parentInfo.eventName
            projectName = marker.parentInfo.projectName
            libraryName = marker.parentInfo.libraryName
            iconImage = marker.icon.fileName
            imageFileName = isSingleFrame
                ? "marker-placeholder.\(imageFormat)"
                : "\(marker.id(pathSafe: idMode)).\(imageFormat)"
        }
        
        public func dictionaryRepresentation() -> OrderedDictionary<Field, String> {
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
                .videoRoles: videoRoles,
                .audioRoles: audioRoles,
                .eventName: eventName,
                .projectName: projectName,
                .libraryName: libraryName,
                .iconImage: iconImage,
                .imageFileName: imageFileName
            ]
        }
    }
}

extension CSVExportProfile.PreparedMarker {
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
    
    fileprivate var status: CSVExportProfile.PreparedMarker.Status {
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
