import MarkersExtractor

func main() {
    if CommandLine.arguments.contains("--help-labels") {
        print("List of available label headers:")
        for header in MarkerHeader.allCases {
            print("    '\(header.rawValue)'")
        }
        return
    }

    do {
        var command = try MarkersExtractorCLI.parseAsRoot()
        try command.run()
    } catch {
        MarkersExtractorCLI.exit(withError: error)
    }
}

main()
