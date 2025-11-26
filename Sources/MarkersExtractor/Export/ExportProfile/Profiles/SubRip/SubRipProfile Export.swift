//
//  SubRipProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import DAWFileKit
import Foundation
import Logging
import OrderedCollections
import SwiftExtensions
import TimecodeKitCore

extension SubRipProfile {
    public func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        tcStringFormat: Timecode.StringFormat,
        useChapterMarkerPosterOffset: Bool,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker] {
        markers.map {
            PreparedMarker(
                marker: $0,
                idMode: idMode,
                timeFormat: .srt
            )
        }
    }
    
    public func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        let subtitles = preparedMarkers.map {
            SRTFile.Subtitle(
                timeRange: $0.inTime ... $0.outTime,
                text: $0.name,
                textCoordinates: nil
            )
        }
        let srtFile = SRTFile(subtitles: subtitles)
        
        let srtData = try srtFile.rawData()
        
        try srtData.write(to: payload.srtPath)
    }
    
    public func resultFileContent(payload: Payload) throws -> ExportResult.ResultDictionary {
        [.srtManifestPath: .url(payload.srtPath)]
    }
    
    public func tableManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String> {
        // unused
        [:]
    }
}
