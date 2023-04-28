//
//  MIDIFileExportProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import CodableCSV
import Foundation
import Logging
import OrderedCollections
import DAWFileKit
import MIDIKitSMF

extension MIDIFileExportProfile {
    public func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker] {
        markers.map {
            PreparedMarker(
                $0,
                idMode: idMode
            )
        }
    }
    
    public func writeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        let dawMarkers = preparedMarkers.map { $0.dawMarker() }
        
        var buildMessages: [String] = []
        let midiFile = try MIDIFile(
            converting: dawMarkers,
            tempo: 120.0,
            startTimecode: payload.sessionStartTimecode,
            includeComments: false,
            buildMessages: &buildMessages
        )
        
        buildMessages.forEach {
            logger?.info("MIDI File: \($0)")
        }
        
        let data = try midiFile.rawData()
        try data.write(to: payload.midiFilePath)
    }
    
    public func doneFileContent(payload: Payload) throws -> Data {
        let dict = ["midiFilePath": payload.midiFilePath.path]
        let data = try dictToJSON(dict)
        return data
    }
    
    public func manifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String> {
        var dict: OrderedDictionary<ExportField, String> = [
            .position: marker.position,
            .name: marker.name
        ]
        
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
    
    public var imageFileName: String {
        UUID().uuidString // never used, just dummy
    }
    
    public init(
        _ marker: Marker,
        idMode: MarkerIDMode
    ) {
        name = marker.name
        position = marker.positionTimecodeString()
        frameRate = marker.frameRate()
        subFramesBase = marker.subFramesBase()
    }
    
    /// Convert to a DAWFileKit `DAWMarker`
    func dawMarker() -> DAWMarker {
        DAWMarker(
            storage: .init(
                value: .timecodeString(position),
                frameRate: frameRate,
                base: subFramesBase
            ),
            name: name,
            comment: nil
        )
    }
}
