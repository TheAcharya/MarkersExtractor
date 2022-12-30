import Foundation

public protocol ExportProfile
    where PreparedMarker.Field == Field
{
    associatedtype Field: ExportField
    associatedtype Payload: ExportPayload
    associatedtype PreparedMarker: ExportMarker
    
    /// Exports markers to disk.
    /// Writes metadata files, images, and any other resources necessary.
    static func export(
        markers: [Marker],
        idMode: MarkerIDMode,
        videoPath: URL,
        outputPath: URL,
        payload: Payload,
        imageSettings: ExportImageSettings<Field>
    ) throws
    
    /// Converts raw FCP markers to the native format needed for export.
    static func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        payload: Payload,
        imageSettings: ExportImageSettings<Field>,
        isSingleFrame: Bool
    ) -> [PreparedMarker]
    
    /// Encode and write metadata manifest file to disk. (Such as csv file)
    static func writeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload
    ) throws
}
