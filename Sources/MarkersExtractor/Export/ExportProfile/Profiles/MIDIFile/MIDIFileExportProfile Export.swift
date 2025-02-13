//
//  MIDIFileExportProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import DAWFileKit
import Foundation
import Logging
import MIDIKitSMF
import OrderedCollections

extension MIDIFileExportProfile {
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
                timeFormat: .timecode(stringFormat: tcStringFormat)
            )
        }
    }
    
    public func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        try writeManifest(preparedMarkers, payload: payload, noMedia: noMedia)
    }
    
    func writeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        let dawMarkers = preparedMarkers.map { $0.dawMarker() }
        
        var buildMessages: [String] = []
        let midiFile = try MIDIFile(
            converting: dawMarkers,
            tempo: 120.0,
            startTimecode: payload.timelineStartTimecode,
            includeComments: false,
            buildMessages: &buildMessages
        )
        
        buildMessages.forEach {
            logger?.info("MIDI File diagnostic: \($0)")
        }
        
        let data = try midiFile.rawData()
        try data.write(to: payload.midiFilePath)
    }
    
    public func resultFileContent(payload: Payload) throws -> ExportResult.ResultDictionary {
        [.midiFilePath: .url(payload.midiFilePath)]
    }
    
    public func tableManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String> {
        // can ignore `structure` since MIDI File is proprietary
        // and does not have multiple format variants
        
        var dict: OrderedDictionary<ExportField, String> = [:]
        
        dict[.position] = marker.position
        dict[.name] = marker.name
        
        if !noMedia {
            dict[.imageFileName] = marker.imageFileName
        }
        
        return dict
    }
}
