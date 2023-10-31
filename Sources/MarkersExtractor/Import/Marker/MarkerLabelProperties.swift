//
//  MarkerLabelProperties.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit

public struct MarkerLabelProperties: Sendable {
    public enum AlignHorizontal: String, CaseIterable, Sendable {
        case left
        case center
        case right
    }

    public enum AlignVertical: String, CaseIterable, Sendable {
        case top
        case center
        case bottom
    }

    let fontName: String
    let fontMaxSize: Int
    let fontColor: NSColor
    let fontStrokeColor: NSColor
    let fontStrokeWidth: Int?
    let alignHorizontal: AlignHorizontal
    let alignVertical: AlignVertical
}
