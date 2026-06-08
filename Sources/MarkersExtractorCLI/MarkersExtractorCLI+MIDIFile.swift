//
//  MarkersExtractorCLI+MIDIFile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import DAWFileTools
import Foundation
import Logging
import MarkersExtractor

extension MarkersExtractorCLI {
    struct MIDIFileOptions: ParsableArguments {
        @Flag(
            name: [.customLong("allow-utf8-midi")],
            help: "Allows UTF-8 text encoding when exporting a MIDI file. Note that not all music software supports reading UTF-8 text events from MIDI files."
        )
        var isMIDIFileUTF8EncodingAllowed: Bool = MarkersExtractor.Settings.Defaults.isMIDIFileUTF8EncodingAllowed
    }
}
