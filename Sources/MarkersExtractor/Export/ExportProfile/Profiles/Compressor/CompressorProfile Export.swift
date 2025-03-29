//
//  CompressorProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import OTCore
import TimecodeKitCore

extension CompressorProfile {
    public func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        tcStringFormat: Timecode.StringFormat,
        useChapterMarkerPosterOffset: Bool,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker] {
        var preparedMarkers = markers.map {
            PreparedMarker(
                marker: $0,
                idMode: idMode,
                mediaInfo: mediaInfo,
                tcStringFormat: tcStringFormat,
                timeFormat: .timecode(stringFormat: tcStringFormat),
                offsetToTimelineStart: true,
                useChapterMarkerPosterOffset: useChapterMarkerPosterOffset
            )
        }
        
        // There is a bug in Compressor whereby the last marker is inadvertently omitted during the import process.
        // As a workaround, the last marker is duplicated and renamed as "Dummy Marker".
        if let lastMarker = markers.last {
            let nullMarker = PreparedMarker(
                marker: Marker(
                    type: lastMarker.type,
                    name: "Dummy Marker",
                    notes: lastMarker.notes,
                    roles: lastMarker.roles,
                    position: lastMarker.position,
                    parentInfo: lastMarker.parentInfo,
                    metadata: lastMarker.metadata,
                    xmlPath: lastMarker.xmlPath
                ),
                idMode: idMode,
                mediaInfo: mediaInfo,
                tcStringFormat: tcStringFormat,
                timeFormat: .timecode(stringFormat: tcStringFormat),
                offsetToTimelineStart: true,
                useChapterMarkerPosterOffset: useChapterMarkerPosterOffset
            )
            preparedMarkers.append(nullMarker)
        }
        
        return preparedMarkers
    }
    
    public func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        let rows = dictsToRows(preparedMarkers, includeHeader: false, noMedia: noMedia)
        
        let txt = rows
            .map { $0.joined(separator: "\t") }
            .joined(separator: "\n")
        
        guard let txtData = txt.data(using: .utf8)
        else {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not encode text file."
            ))
        }
        
        try txtData.write(to: payload.txtPath)
    }
    
    public func resultFileContent(payload: Payload) throws -> ExportResult.ResultDictionary {
        [
            .txtManifestPath: .url(payload.txtPath)
        ]
    }
    
    public func tableManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String> {
        var dict: OrderedDictionary<ExportField, String> = [:]
        
        dict[.position] = marker.position
        dict[.name] = marker.name
        
        return dict
    }
    
    public func nestedManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, ExportFieldValue> {
        var dict: OrderedDictionary<ExportField, ExportFieldValue> = [:]
        
        dict[.position] = .string(marker.position)
        dict[.name] = .string(marker.name)
        
        return dict
    }
}