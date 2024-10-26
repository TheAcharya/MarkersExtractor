//
//  TestResource.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Testing
import TestingExtensions

// NOTE: DO NOT name any folders "Resources". Xcode may fail to build targets.

/// Resources files on disk used for unit testing.
extension TestResource {
    static let videoTrack_29_97_Start_00_00_00_00 = TestResource.File(
        name: "VideoTrack_29_97_Start-00-00-00-00", ext: "mp4", subFolder: "Media Files"
    )
}
