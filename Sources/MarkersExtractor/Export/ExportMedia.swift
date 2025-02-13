//
//  ExportMedia.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Export media information packet.
public struct ExportMedia {
    var videoURL: URL
    var imageSettings: ExportImageSettings
}

extension ExportMedia: Equatable { }

extension ExportMedia: Hashable { }

extension ExportMedia: Sendable { }
