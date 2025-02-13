//
//  ImageDescriptor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TimecodeKitCore

struct ImageDescriptor {
    let absoluteTimecode: Timecode
    let offsetFromVideoStart: Timecode
    let filename: String
    let label: String?
}

extension ImageDescriptor: Equatable { }

extension ImageDescriptor: Hashable { }

extension ImageDescriptor: Sendable { }
