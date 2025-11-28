//
//  Test Utilities.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

@testable import MarkersExtractor
import SwiftTimecodeCore

/// Convenience timecode constructor.
/// Final Cut Pro always uses 80 subframes base.
func tc(_ string: String, at frameRate: TimecodeFrameRate) -> Timecode {
    try! Timecode(
        .string(string),
        at: frameRate,
        base: .max80SubFrames,
        limit: .max24Hours
    )
}

/// Convenience timecode constructor.
/// Final Cut Pro always uses 80 subframes base.
func tc(_ components: Timecode.Components, at frameRate: TimecodeFrameRate) -> Timecode {
    try! Timecode(
        .components(components),
        at: frameRate,
        base: .max80SubFrames,
        limit: .max24Hours
    )
}
