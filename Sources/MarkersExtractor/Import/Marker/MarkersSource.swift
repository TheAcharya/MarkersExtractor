//
//  MarkersSource.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum MarkersSource: String, Equatable, Hashable, CaseIterable, Sendable {
    case markers
    case markersAndCaptions
    case captions
}
