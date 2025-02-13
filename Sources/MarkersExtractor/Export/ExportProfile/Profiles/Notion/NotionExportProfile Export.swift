//
//  NotionExportProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKitCore

extension NotionExportProfile {
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
                mediaInfo: mediaInfo, 
                tcStringFormat: tcStringFormat,
                timeFormat: .timecode(stringFormat: tcStringFormat), 
                useChapterMarkerPosterOffset: useChapterMarkerPosterOffset
            )
        }
    }
    
    public func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        try jsonWriteManifest(
            jsonPath: payload.jsonPath,
            noMedia: noMedia,
            preparedMarkers
        )
    }
    
    public func resultFileContent(payload: Payload) throws -> ExportResult.ResultDictionary {
        [
            .jsonManifestPath: .url(payload.jsonPath)
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
        dict[.reel] = marker.reel
        dict[.scene] = marker.scene
        dict[.take] = marker.take
        dict[.position] = marker.position
        dict[.clipType] = marker.clipType
        dict[.clipName] = marker.clipName
        dict[.clipIn] = marker.clipIn
        dict[.clipOut] = marker.clipOut
        dict[.clipDuration] = marker.clipDuration
        dict[.clipKeywords] = marker.clipKeywordsFlat
        dict[.videoRole] = marker.videoRole
        dict[.audioRole] = marker.audioRoleFlat
        dict[.eventName] = marker.eventName
        dict[.projectName] = marker.projectName
        dict[.libraryName] = marker.libraryName
        dict[.iconImage] = marker.icon.fileName
        
        if !noMedia {
            dict[.imageFileName] = marker.imageFileName
        }
        
        dict[.xmlPath] = marker.xmlPath
        
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
        dict[.reel] = .string(marker.reel)
        dict[.scene] = .string(marker.scene)
        dict[.take] = .string(marker.take)
        dict[.position] = .string(marker.position)
        dict[.clipType] = .string(marker.clipType)
        dict[.clipName] = .string(marker.clipName)
        dict[.clipIn] = .string(marker.clipIn)
        dict[.clipOut] = .string(marker.clipOut)
        dict[.clipDuration] = .string(marker.clipDuration)
        dict[.clipKeywords] = .array(marker.clipKeywordsArray)
        dict[.videoRole] = .string(marker.videoRole)
        dict[.audioRole] = .array(marker.audioRoleArray)
        dict[.eventName] = .string(marker.eventName)
        dict[.projectName] = .string(marker.projectName)
        dict[.libraryName] = .string(marker.libraryName)
        dict[.iconImage] = .string(marker.icon.fileName)
        
        if !noMedia {
            dict[.imageFileName] = .string(marker.imageFileName)
        }
        
        dict[.xmlPath] = .string(marker.xmlPath)
        
        return dict
    }
}
