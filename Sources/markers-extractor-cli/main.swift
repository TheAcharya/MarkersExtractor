//
//  main.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import MarkersExtractor

func main() {
    do {
        var command = try MarkersExtractorCLI.parseAsRoot()
        try command.run()
    } catch {
        MarkersExtractorCLI.exit(withError: error)
    }
}

main()
