//
//  Marker Metadata.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

extension Marker {
    struct Metadata {
        var reel: String
        var scene: String
        var take: String
    }
}

extension Marker.Metadata: Equatable { }

extension Marker.Metadata: Hashable { }

extension Marker.Metadata: Sendable { }
