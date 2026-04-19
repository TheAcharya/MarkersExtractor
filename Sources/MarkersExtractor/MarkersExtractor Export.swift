//
//  MarkersExtractor Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import SwiftTimecodeCore

extension MarkersExtractor {
    func export(
        timelineName: String,
        timelineStartTimecode: Timecode,
        media: ExportMedia?,
        markers: [Marker],
        outputURL: URL,
        parentProgress: ParentProgress? = nil
    ) async throws -> ExportResult {
        switch settings.exportFormat {
        case .airtable:
            try await export(
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
        case .compressor:
            try await export(
                for: CompressorProfile.self,
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
            try await export(
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
        case .json:
            try await export(
                for: JSONProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(
                    timelineName: timelineName,
                    outputURL: outputURL
                ),
                parentProgress: parentProgress
            )
        case .markdown:
            try await export(
                for: MarkdownProfile.self,
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
            try await export(
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
            try await export(
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
        case .srt:
            try await export(
                for: SubRipProfile.self,
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
            try await export(
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
        case .xlsx:
            try await export(
                for: ExcelProfile.self,
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
            try await export(
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
            idMode: settings.idNamingMode,
            media: media,
            tcStringFormat: timecodeStringFormat,
            useChapterMarkerPosterOffset: settings.useChapterMarkerThumbnails,
            outputURL: outputURL,
            payload: payload,
            resultFilePath: settings.resultFilePath,
            logger: logger,
            parentProgress: parentProgress
        )
    }
}
