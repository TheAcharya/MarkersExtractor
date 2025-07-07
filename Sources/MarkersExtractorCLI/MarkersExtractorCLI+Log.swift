//
//  MarkersExtractorCLI+Log.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import Foundation
import Logging
import MarkersExtractor
import DAWFileKit

extension MarkersExtractorCLI {
    struct LogOptions: ParsableArguments {
        @Option(
            help: ArgumentHelp(
                "Path including filename to create a JSON result file. If this option is not passed, it won't be created.",
                valueName: "path"
            ),
            transform: URL.init(fileURLWithPath:)
        )
        var resultFilePath: URL? = MarkersExtractor.Settings.Defaults.resultFilePath
        
        @Option(help: "Log file path.", transform: URL.init(fileURLWithPath:))
        var log: URL?
        
        @Option(
            help: ArgumentHelp(
                "Log level.",
                valueName: caseIterableValueString(for: Logger.Level.self)
            )
        )
        var logLevel: Logger.Level = .info
        
        @Flag(name: [.customLong("quiet")], help: "Disable log.")
        var logQuiet = false
        
        @Flag(name: [.customLong("no-progress")], help: "Disable progress logging.")
        var noProgressLogging = false
    }
}
