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
    ) throws {
        switch s.exportFormat {
        case .airtable:
            try export(
                for: AirtableExportProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(projectName: projectName, outputURL: outputURL)
            )
        case .midi:
            try export(
                for: MIDIFileExportProfile.self,
                media: media,
                markers: markers,
                outputURL: outputURL,
                payload: .init(projectName: projectName,
                               outputURL: outputURL,
                               sessionStartTimecode: projectStartTimecode)
            )
        case .notion:
            try export(
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
    ) throws {
        try P(logger: logger).export(
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
