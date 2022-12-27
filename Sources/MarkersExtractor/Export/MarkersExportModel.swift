import Foundation

public protocol MarkersExportModel
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
        idMode: MarkerIDMode,
        videoPath: URL,
        outputPath: URL,
        payload: Payload,
        imageSettings: MarkersExportImageSettings<Field>
    ) throws
    
    /// Converts raw FCP markers to the native format needed for export.
    static func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        payload: Payload,
        imageSettings: MarkersExportImageSettings<Field>,
        isSingleFrame: Bool
    ) -> [PreparedMarker]
    
    /// Encode and write metadata manifest file to disk. (Such as csv file)
    static func writeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload
    ) throws
}
