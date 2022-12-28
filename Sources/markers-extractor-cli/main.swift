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
