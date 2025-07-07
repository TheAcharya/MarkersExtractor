//
//  MarkersExtractorCLI+General.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import Foundation
import Logging
import MarkersExtractor
import DAWFileKit

extension MarkersExtractorCLI {
    struct GeneralOptions: ParsableArguments {
        @Option(
            help: ArgumentHelp(
                "Metadata export format.",
                valueName: caseIterableValueString(for: ExportProfileFormat.self)
            )
        )
        var exportFormat: ExportProfileFormat = MarkersExtractor.Settings.Defaults.exportFormat
        
        @Flag(help: ArgumentHelp("Enable output of timecode subframes."))
        var enableSubframes: Bool = MarkersExtractor.Settings.Defaults.enableSubframes
        
        @Option(
            name: [.customLong("folder-format")],
            help: ArgumentHelp(
                "Output folder name format.",
                valueName: caseIterableValueString(for: ExportFolderFormat.self)
            )
        )
        var exportFolderFormat: ExportFolderFormat = MarkersExtractor.Settings.Defaults.exportFolderFormat
        
        @Option(
            help: ArgumentHelp(
                "Marker naming mode. This affects Marker IDs and image filenames.",
                valueName: caseIterableValueString(for: MarkerIDMode.self)
            )
        )
        var idNamingMode: MarkerIDMode = MarkersExtractor.Settings.Defaults.idNamingMode
    }
}
