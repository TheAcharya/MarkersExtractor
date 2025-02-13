//
//  MarkerLabelProperties AlignVertical.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

extension MarkerLabelProperties {
    public enum AlignVertical: String {
        case top
        case center
        case bottom
    }
}

extension MarkerLabelProperties.AlignVertical: Equatable { }

extension MarkerLabelProperties.AlignVertical: Hashable { }

extension MarkerLabelProperties.AlignVertical: CaseIterable { }

extension MarkerLabelProperties.AlignVertical: Identifiable {
    public var id: Self { self }
}

extension MarkerLabelProperties.AlignVertical: Sendable { }
