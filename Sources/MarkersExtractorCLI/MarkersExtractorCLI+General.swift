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
            help: ArgumentHelp(
                "Annotations to import. If captions are used, their start timecode determines their position.",
                valueName: caseIterableValueString(for: MarkersSource.self)
            )
        )
        var markersSource: MarkersSource = MarkersExtractor.Settings.Defaults.markersSource
        
        @Flag(
            help: ArgumentHelp(
                "For chapter markers, use their thumbnail pin position for thumbnail image generation."
            )
        )
        var useChapterMarkerThumbnails: Bool = MarkersExtractor.Settings.Defaults.useChapterMarkerThumbnails
        
        @Option(
            name: [.customLong("exclude-role")],
            help: ArgumentHelp(
                "Exclude markers with a specified role. This argument can be supplied more than once to apply multiple role exclusions.",
                valueName: "name"
            )
        )
        var excludeRoles: [String] = []
        
        @Flag(
            name: [.customLong("include-disabled")],
            help: ArgumentHelp(
                "Include markers on disabled clips. By default, disabled clips are ignored."
            )
        )
        var includeDisabled: Bool = MarkersExtractor.Settings.Defaults.includeDisabled
        
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
