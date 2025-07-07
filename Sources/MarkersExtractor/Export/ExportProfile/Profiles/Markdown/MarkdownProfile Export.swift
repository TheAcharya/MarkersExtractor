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
    ) throws {
        // Get the project name from the first marker (assumes all markers have the same project name)
        let projectName = preparedMarkers.first!.projectName
        
        // Create the header with the project name
        let header = "# \(projectName)\n\n"
        
        // Get rows without header
        let rows = dictsToRows(preparedMarkers, includeHeader: false, noMedia: noMedia)
        
        // Flatten data with header
        let md = header + rows
            .map { $0.joined(separator: " ") }
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
    
    private func getTypeEmoji(type: String, isChecked: Bool) -> String {
        // If the item is checked, always return green circle regardless of type
        if isChecked {
            return "🟢"
        }
        
        // Otherwise, choose emoji based on type
        switch type {
        case "Standard":
            return "🟣"
        case "To Do":
            return "🔴"
        case "Chapter":
            return "🟠"
        case "Caption":
            return "🔵"
        default:
            return type // Just return the original type if somehow there's something unexpected
        }
    }
    
    public func tableManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String> {
        var dict: OrderedDictionary<ExportField, String> = [:]
        
        let isChecked = marker.checked == "true"
        
        // Convert true/false to markdown checkbox format
        dict[.checked] = isChecked ? "- [x]" : "- [ ]"
        dict[.position] = marker.position + " -"
        
        // Replace the type text with the appropriate emoji
        dict[.type] = getTypeEmoji(type: marker.type, isChecked: isChecked)
        
        // Add a dash separator before notes if they exist
        if !marker.name.isEmpty && !marker.notes.isEmpty {
            dict[.name] = marker.name + " -"
        } else {
            dict[.name] = marker.name
        }
        
        dict[.notes] = marker.notes
        
        // We don't include projectName in the output fields as it will be used only for the header
        
        return dict
    }
    
    public func nestedManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, ExportFieldValue> {
        var dict: OrderedDictionary<ExportField, ExportFieldValue> = [:]
        
        let isChecked = marker.checked == "true"
        
        // Convert true/false to markdown checkbox format
        dict[.checked] = .string(isChecked ? "- [x]" : "- [ ]")
        dict[.position] = .string(marker.position + " -")
        
        // Replace the type text with the appropriate emoji
        dict[.type] = .string(getTypeEmoji(type: marker.type, isChecked: isChecked))
        
        // Add a dash separator before notes if they exist
        if !marker.name.isEmpty && !marker.notes.isEmpty {
            dict[.name] = .string(marker.name + " -")
        } else {
            dict[.name] = .string(marker.name)
        }
        
        dict[.notes] = .string(marker.notes)
        
        // We don't include projectName in the output fields as it will be used only for the header
        
        return dict
    }
}
