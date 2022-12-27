import Foundation
import OrderedCollections

extension Marker {
    func dictionaryRepresentation(
        _ imageFormat: MarkerImageFormat,
        isSingleFrame: Bool
    ) -> OrderedDictionary<MarkerHeader, String> {
        [
            .id: id,
            .name: name,
            .type: type.rawValue,
            .checked: String(checked),
            .status: status.rawValue,
            .notes: notes,
            .position: timecode,
            .clipName: parentClipName,
            .clipDuration: parentClipDurationTimecode,
            .role: role,
            .eventName: parentEventName,
            .projectName: parentProjectName,
            .libraryName: parentLibraryName,
            .iconImage: icon.fileName,
            .imageName: isSingleFrame
                ? "marker-placeholder.\(imageFormat)"
                : "\(idPathSafe).\(imageFormat)",
        ]
    }
}
