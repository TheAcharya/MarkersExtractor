//
//  CLIEntry.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import MarkersExtractor

@main
struct CLIEntry {
    static func main() async {
        do {
            var command = try MarkersExtractorCLI.parseAsRoot()
            try command.run()
        } catch {
            MarkersExtractorCLI.exit(withError: error)
        }
    }
}
