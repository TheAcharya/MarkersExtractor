//
//  MarkersExtractorCLI+Media.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import DAWFileTools
import Foundation
import Logging
import MarkersExtractor

extension MarkersExtractorCLI {
    struct MediaOptions: ParsableArguments {
        @Option(
            name: [.customLong("media-search-path")],
            help: ArgumentHelp(
                "Media search path. This argument can be supplied more than once to use multiple paths. (default: same folder as fcpxml(d))",
                valueName: "path"
            ),
            transform: URL.init(fileURLWithPath:)
        )
        var mediaSearchPaths: [URL] = []
        
        @Flag(
            name: [.customLong("no-media")],
            help: "Bypass media. No thumbnails will be generated."
        )
        var noMedia: Bool = MarkersExtractor.Settings.Defaults.noMedia
    }
}
