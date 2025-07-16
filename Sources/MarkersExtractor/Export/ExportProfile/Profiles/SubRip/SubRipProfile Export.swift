//
//  SubRipProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import OTCore
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
                timeFormat: .timecode(stringFormat: tcStringFormat)
            )
        }
    }
    
    public func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws {
        var srtContent = ""
        
        for (index, marker) in preparedMarkers.enumerated() {
            let markerNumber = index + 1
            let startTime = marker.convertToSRTTime(timecode: marker.position)
            
            // Use improved end time calculation that properly handles milliseconds
            let endTime = marker.calculateEndTime(startTime: startTime, durationSeconds: subtitleDurationSeconds)
            
            srtContent += "\(markerNumber)\n"
            srtContent += "\(startTime) --> \(endTime)\n"
            srtContent += "\(marker.name)\n\n"
        }
        
        // Validate SRT content before writing
        guard validateSRTContent(srtContent) else {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Generated SRT content is invalid."
            ))
        }
        
        guard let srtData = srtContent.data(using: .utf8) else {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not encode SRT file."
            ))
        }
        
        try srtData.write(to: payload.srtPath)
    }
    
    private func validateSRTContent(_ content: String) -> Bool {
        // A basic validation to ensure timestamps are properly formatted
        let lines = content.components(separatedBy: .newlines)
        let timePattern = try? NSRegularExpression(pattern: "^\\d{2}:\\d{2}:\\d{2},\\d{3}$")
        
        for line in lines {
            if line.contains(" --> ") {
                let times = line.components(separatedBy: " --> ")
                guard times.count == 2 else { return false }
                
                for time in times {
                    // Check time format: HH:MM:SS,mmm
                    let timeRange = NSRange(location: 0, length: time.utf16.count)
                    if timePattern?.firstMatch(in: time, options: [], range: timeRange) == nil {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    public func resultFileContent(payload: Payload) throws -> ExportResult.ResultDictionary {
        [.srtManifestPath: .url(payload.srtPath)]
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
}