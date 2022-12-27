import AVFoundation
import CodableCSV
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

extension CSVExportModel {
    public static func export(
        markers: [Marker],
        idMode: MarkerIDMode,
        csvPath: URL,
        videoPath: URL,
        outputPath: URL,
        imageSettings: MarkersExportImageSettings<Field>
    ) throws {
        try export(
            markers: markers,
            videoPath: videoPath,
            outputPath: outputPath,
            payload: Payload(idMode: idMode, csvPath: csvPath),
            imageSettings: imageSettings
        )
    }
    
    public static func prepareMarkers(
        markers: [Marker],
        payload: Payload,
        imageSettings: MarkersExportImageSettings<Field>,
        isSingleFrame: Bool
    ) -> [PreparedMarker] {
        markers.map {
            PreparedMarker(
                $0,
                idMode: payload.idMode,
                imageFormat: imageSettings.format,
                isSingleFrame: isSingleFrame
            )
        }
    }
    
    public static func encodeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload
    ) throws {
        let rows = dictsToRows(preparedMarkers)
        
        let csvData = try CSVWriter.encode(rows: rows, into: Data.self)
        try csvData.write(to: payload.csvPath)
    }
    
    private static func dictsToRows(
        _ preparedMarkers: [PreparedMarker]
    ) -> [[String]] {
        let dicts = preparedMarkers.map { $0.dictionaryRepresentation() }
        guard !dicts.isEmpty else { return [] }
        
        var result = [Array(dicts[0].keys.map { $0.rawValue })]
        
        for row in dicts {
            result += [Array(row.values)]
        }
        
        return result
    }
}
