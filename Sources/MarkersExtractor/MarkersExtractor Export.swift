//
//  MarkersExtractor Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TimecodeKit

extension MarkersExtractor {
    func export(
        timelineName: String,
        timelineStartTimecode: Timecode,
        media: ExportMedia?,
        markers: [Marker],
        outputURL: URL,
        parentProgress: ParentProgress? = nil
    ) async throws -> ExportResult {
        switch s.exportFormat {
        case .airtable:
            return try await export(
                for: AirtableExportProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(
                    timelineName: timelineName,
                    outputURL: outputURL
                ),
                parentProgress: parentProgress
            )
        case .csv:
            return try await export(
                for: CSVProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(
                    timelineName: timelineName,
                    outputURL: outputURL
                ),
                parentProgress: parentProgress
            )
            
        case .midi:
            return try await export(
                for: MIDIFileExportProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(
                    timelineName: timelineName,
                    outputURL: outputURL,
                    timelineStartTimecode: timelineStartTimecode
                ),
                parentProgress: parentProgress
            )
        case .notion:
            return try await export(
                for: NotionExportProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(
                    timelineName: timelineName,
                    outputURL: outputURL
                ),
                parentProgress: parentProgress
            )
            
        case .tsv:
            return try await export(
                for: TSVProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(
                    timelineName: timelineName,
                    outputURL: outputURL
                ),
                parentProgress: parentProgress
            )
            
        case .youtube:
            return try await export(
                for: YouTubeProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(
                    timelineName: timelineName,
                    outputURL: outputURL
                ),
                parentProgress: parentProgress
            )
        }
    }
    
    private func export<P: ExportProfile>(
        for format: P.Type,
        media: ExportMedia?,
        markers: [Marker],
        outputURL: URL,
        payload: P.Payload,
        parentProgress: ParentProgress?
    ) async throws -> ExportResult {
        try await P(logger: logger).export(
            markers: markers,
            idMode: s.idNamingMode,
            media: media,
            tcStringFormat: timecodeStringFormat, 
            useChapterMarkerPosterOffset: s.useChapterMarkerThumbnails,
            outputURL: outputURL,
            payload: payload,
            resultFilePath: s.resultFilePath,
            logger: logger,
            parentProgress: parentProgress
        )
    }
}
