import Foundation

protocol MarkersExportModel
    where Field: Hashable,
    Field: RawRepresentable,
    Field.RawValue == String,
    PreparedMarker.Field == Field
{
    associatedtype Field
    associatedtype Payload: MarkersExportModelPayload
    associatedtype PreparedMarker: MarkersExportPreparedMarker
    
    /// Exports markers to disk.
    /// Writes metadata files, images, and any other resources necessary.
    static func export(
        markers: [Marker],
        videoPath: URL,
        outputPath: URL,
        payload: Payload,
        imageSettings: MarkersExportImageSettings<Field>
    ) throws
    
    /// Converts raw FCP markers to the native format needed for export.
    static func prepareMarkers(
        markers: [Marker],
        payload: Payload,
        imageSettings: MarkersExportImageSettings<Field>,
        isSingleFrame: Bool
    ) -> [PreparedMarker]
    
    static func encodeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload
    ) throws
}
