//
//  MarkerIDMode.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Marker ID generation mode.
public enum MarkerIDMode: String {
    case timelineNameAndTimecode
    case name
    case notes
}

extension MarkerIDMode: Equatable { }

extension MarkerIDMode: Hashable { }

extension MarkerIDMode: CaseIterable { }

extension MarkerIDMode: Identifiable {
    public var id: Self { self }
}

extension MarkerIDMode: Sendable { }
