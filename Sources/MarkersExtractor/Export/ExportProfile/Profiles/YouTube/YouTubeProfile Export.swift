//
//  YouTubeProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import SwiftExtensions
import SwiftTimecodeCore

extension YouTubeProfile {
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
                timeFormat: .realTime(stringFormat: .hh_mm_ss),
                offsetToTimelineStart: true,
                useChapterMarkerPosterOffset: useChapterMarkerPosterOffset
            )
        }
        
        // YouTube requires the first marker to be at timestamp 00:00:00.
        // If one doesn't exist, add one at the start of the list with a generic name.
        if let firstMarker = markers.first,
           let firstPreparedMarker = preparedMarkers.first,
           Time(string: firstPreparedMarker.position) != Time(seconds: 0)
        {
            let marker = Marker(
                type: .marker(.standard),
                name: "Introduction",
                notes: "",
                roles: MarkerRoles(),
                position: Timecode(.zero, using: firstMarker.position.properties),
                parentInfo: firstMarker.parentInfo,
                metadata: Marker.Metadata(reel: "", scene: "", take: ""),
                xmlPath: "" // does not exist in the XML
            )
            let zeroMarker = PreparedMarker(
                marker: marker,
                idMode: idMode,
                mediaInfo: mediaInfo,
                tcStringFormat: tcStringFormat,
                timeFormat: .realTime(stringFormat: .hh_mm_ss),
                offsetToTimelineStart: false,
                useChapterMarkerPosterOffset: useChapterMarkerPosterOffset
            )
            logger?.info(
                "Missing initial YouTube chapter marker at required timestamp 00:00:00. Inserting 'Introduction' marker at start of chapter marker list."
            )
            preparedMarkers.insert(zeroMarker, at: 0)
        }
        
        return preparedMarkers
    }
    
    public func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) async throws {
        let rows = dictsToRows(preparedMarkers, includeHeader: false, noMedia: noMedia)
        
        // flatten data
        let txt = rows
            .map { $0.joined(separator: " ") }
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
