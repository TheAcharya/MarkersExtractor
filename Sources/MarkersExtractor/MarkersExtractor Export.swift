//
//  MarkersExtractor Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TimecodeKit

extension MarkersExtractor {
    func export(
        projectName: String,
        projectStartTimecode: Timecode,
        media: ExportMedia?,
        markers: [Marker],
        outputURL: URL
    ) async throws {
        switch s.exportFormat {
        case .airtable:
            try await export(
                for: AirtableExportProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(projectName: projectName, outputURL: outputURL)
            )
        case .midi:
            try await export(
                for: MIDIFileExportProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(projectName: projectName,
                               outputURL: outputURL,
                               sessionStartTimecode: projectStartTimecode)
            )
        case .notion:
            try await export(
                for: NotionExportProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(projectName: projectName, outputURL: outputURL)
            )
        }
    }
    
    private func export<P: ExportProfile>(
        for format: P.Type,
        media: ExportMedia?,
        markers: [Marker],
        outputURL: URL,
        payload: P.Payload
    ) async throws {
        try await P(logger: logger).export(
            markers: markers,
            idMode: s.idNamingMode,
            media: media,
            tcStringFormat: timecodeStringFormat,
            outputURL: outputURL,
            payload: payload,
            createDoneFile: s.createDoneFile,
            doneFilename: s.doneFilename,
            logger: logger
        )
    }
}
