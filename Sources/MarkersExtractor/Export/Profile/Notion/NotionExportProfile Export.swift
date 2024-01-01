//
//  NotionExportProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

extension NotionExportProfile {
    public func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        tcStringFormat: Timecode.StringFormat,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker] {
        markers.map {
            PreparedMarker(
                $0,
                idMode: idMode,
                mediaInfo: mediaInfo,
                tcStringFormat: tcStringFormat
            )
        }
    }
    
    public func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        try csvWriteManifest(
            csvPath: payload.csvPayload.csvPath,
            noMedia: noMedia,
            preparedMarkers
        )
        
        try jsonWriteManifest(
            jsonPath: payload.jsonPayload.jsonPath,
            noMedia: noMedia,
            preparedMarkers
        )
    }
    
    public func resultFileContent(payload: Payload) throws -> ExportResult.ResultDictionary {
        [
            .csvManifestPath: .url(payload.csvPayload.csvPath),
            .jsonManifestPath: .url(payload.jsonPayload.jsonPath)
        ]
    }
    
    public func tableManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String> {
        var dict: OrderedDictionary<ExportField, String> = [:]
        
        dict[.id] = marker.id
        dict[.name] = marker.name
        dict[.type] = marker.type
        dict[.checked] = marker.checked
        dict[.status] = marker.status
        dict[.notes] = marker.notes
        dict[.position] = marker.position
        dict[.clipType] = marker.clipType
        dict[.clipName] = marker.clipName
        dict[.clipDuration] = marker.clipDuration
        dict[.videoRole] = marker.videoRole
        dict[.audioRole] = marker.audioRole.flat
        dict[.eventName] = marker.eventName
        dict[.projectName] = marker.projectName
        dict[.libraryName] = marker.libraryName
        dict[.iconImage] = marker.icon.fileName
        
        if !noMedia {
            dict[.imageFileName] = marker.imageFileName
        }
        
        return dict
    }
    
    public func nestedManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, ExportFieldValue> {
        var dict: OrderedDictionary<ExportField, ExportFieldValue> = [:]
        
        dict[.id] = .string(marker.id)
        dict[.name] = .string(marker.name)
        dict[.type] = .string(marker.type)
        dict[.checked] = .string(marker.checked)
        dict[.status] = .string(marker.status)
        dict[.notes] = .string(marker.notes)
        dict[.position] = .string(marker.position)
        dict[.clipType] = .string(marker.clipType)
        dict[.clipName] = .string(marker.clipName)
        dict[.clipDuration] = .string(marker.clipDuration)
        dict[.videoRole] = .string(marker.videoRole)
        dict[.audioRole] = .array(marker.audioRole.array)
        dict[.eventName] = .string(marker.eventName)
        dict[.projectName] = .string(marker.projectName)
        dict[.libraryName] = .string(marker.libraryName)
        dict[.iconImage] = .string(marker.icon.fileName)
        
        if !noMedia {
            dict[.imageFileName] = .string(marker.imageFileName)
        }
        
        return dict
    }
}
