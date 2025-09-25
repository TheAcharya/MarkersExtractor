//
//  MarkdownProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import OTCore
import TimecodeKitCore

extension MarkdownProfile {
    public func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        tcStringFormat: Timecode.StringFormat,
        useChapterMarkerPosterOffset: Bool,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker] {
        let preparedMarkers = markers.map {
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
        
        return preparedMarkers
    }
    
    public func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) async throws {
        let title = payload.title
        
        // Create the header with the project name
        let header = "# \(title)\n\n"
        
        // Get rows without header
        let rows: [String] = preparedMarkers.map {
            var output = "- "
            
            output += "\($0.position)"
            
            output += " - \($0.name)"
            
            if let type = $0.type {
                output += " \(type)"
            }
            
            if !$0.notes.isEmpty {
                output += " - \($0.notes)"
            }
            return output
        }
        
        // Flatten data with header
        let md = header + rows
            .joined(separator: "\n")
        
        guard let mdData = md.data(using: .utf8)
        else {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not encode text file."
            ))
        }
        
        try mdData.write(to: payload.mdPath)
    }
    
    public func resultFileContent(payload: Payload) throws -> ExportResult.ResultDictionary {
        [
            .mdManifestPath: .url(payload.mdPath)
        ]
    }
    
    public func tableManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String> {
        var dict: OrderedDictionary<ExportField, String> = [:]
        
        dict[.name] = marker.name
        dict[.type] = marker.type
        dict[.notes] = marker.notes
        dict[.position] = marker.position
        
        return dict
    }
    
    public func nestedManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, ExportFieldValue> {
        var dict: OrderedDictionary<ExportField, ExportFieldValue> = [:]
        
        dict[.name] = .string(marker.name)
        if let markerType = marker.type { dict[.type] = .string(markerType) }
        dict[.notes] = .string(marker.notes)
        dict[.position] = .string(marker.position)
        
        return dict
    }
}
