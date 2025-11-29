//
//  MarkersExtractorCLI+Filter.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import Foundation
import Logging
import MarkersExtractor
import DAWFileTools

extension MarkersExtractorCLI {
    struct FilterOptions: ParsableArguments {
        @Option(
            help: ArgumentHelp(
                "Annotations to import. If captions are used, their start timecode determines their position.",
                valueName: caseIterableValueString(for: MarkersSource.self)
            )
        )
        var markersSource: MarkersSource = MarkersExtractor.Settings.Defaults.markersSource
        
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
    }
}
