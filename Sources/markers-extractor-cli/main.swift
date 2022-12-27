import MarkersExtractor

func main() {
    // oddly handling this manually is the best way to do this. we need ArgumentParser
    // to ignore required arguments if this one is present, but we don't want to make
    // required arguments optional just to achieve that. it breaks the built-in
    // argument validation of ArgumentParser which is undesirable.
    if CommandLine.arguments.contains("--help-labels") {
        MarkersExtractorCLI.printHelpLabels()
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
