//
//  CSVExportProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import CodableCSV
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

extension NotionExportProfile {
    public static func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker] {
        markers.map {
            PreparedMarker(
                $0,
                idMode: idMode,
                mediaInfo: mediaInfo
            )
        }
    }
    
    public static func writeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        try csvWiteManifest(csvPath: payload.csvPath, noMedia: noMedia, preparedMarkers)
    }
    
    public static func doneFileContent(payload: Payload) throws -> Data {
        try csvDoneFileContent(csvPath: payload.csvPath)
    }
    
    public static func manifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String> {
        var dict: OrderedDictionary<ExportField, String> = [
            .id: marker.id,
            .name: marker.name,
            .type: marker.type,
            .checked: marker.checked,
            .status: marker.status,
            .notes: marker.notes,
            .position: marker.position,
            .clipName: marker.clipName,
            .clipDuration: marker.clipDuration,
            .videoRole: marker.videoRole,
            .audioRole: marker.audioRole,
            .eventName: marker.eventName,
            .projectName: marker.projectName,
            .libraryName: marker.libraryName,
            .iconImage: marker.icon.fileName
        ]
        
        if !noMedia {
            dict[.imageFileName] = marker.imageFileName
        }
        
        return dict
    }
}
