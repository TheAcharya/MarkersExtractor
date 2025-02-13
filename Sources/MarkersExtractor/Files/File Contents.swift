//
//  File Contents.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

extension File {
    enum Contents {
        case fileOnDisk(url: URL, cache: Cache?)
        case rawFileContents(Cache)
    }
}

extension File.Contents: Equatable { }

extension File.Contents: Hashable { }

extension File.Contents: Sendable { }
