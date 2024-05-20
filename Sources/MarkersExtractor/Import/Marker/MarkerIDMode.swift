//
//  MarkerIDMode.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum MarkerIDMode: String, CaseIterable, Equatable, Hashable, Sendable {
    case timelineNameAndTimecode
    case name
    case notes
}
