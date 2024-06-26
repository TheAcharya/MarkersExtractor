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

public struct MIDIFileExportMarker: ExportMarker {
    public typealias Icon = EmptyExportIcon
        
    public let position: String
    public let name: String
    public let frameRate: TimecodeFrameRate
    public let subFramesBase: Timecode.SubFramesBase
    
    public var icon: EmptyExportIcon {
        .init(.standard) // never used, just dummy
    }
    
    public let imageFileName: String
    public let imageTimecode: Timecode // not used
    
    public init(
        marker: Marker,
        idMode: MarkerIDMode,
        timeFormat: ExportMarkerTimeFormat
    ) {
        name = marker.name
        position = marker.positionTimeString(format: timeFormat)
        frameRate = marker.frameRate()
        subFramesBase = marker.subFramesBase()
        imageFileName = UUID().uuidString // never used, just dummy
        imageTimecode = marker.imageTimecode(useChapterMarkerPosterOffset: false, offsetToTimelineStart: false) // not used
    }
    
    /// Convert to a DAWFileKit `DAWMarker`.
    func dawMarker() -> DAWMarker {
        DAWMarker(
            storage: .init(
                value: .timecodeString(absolute: position),
                frameRate: frameRate,
                base: subFramesBase
            ),
            name: name,
            comment: nil
        )
    }
}
