//
//  MarkerLabelProperties AlignHorizontal.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

extension MarkerLabelProperties {
    public enum AlignHorizontal: String {
        case left
        case center
        case right
    }
}

extension MarkerLabelProperties.AlignHorizontal: Equatable { }

extension MarkerLabelProperties.AlignHorizontal: Hashable { }

extension MarkerLabelProperties.AlignHorizontal: CaseIterable { }

extension MarkerLabelProperties.AlignHorizontal: Identifiable {
    public var id: Self { self }
}

extension MarkerLabelProperties.AlignHorizontal: Sendable { }
