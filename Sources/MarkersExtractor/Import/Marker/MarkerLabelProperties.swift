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

// MARK: - Constructors

extension MarkerLabelProperties {
    public static func `default`() -> Self {
        let imageLabelFontOpacityDouble = Double(MarkersExtractor.Settings.Defaults.imageLabelFontOpacity) / 100
        
        let fontColor = NSColor(
            hexString: MarkersExtractor.Settings.Defaults.imageLabelFontColor,
            alpha: imageLabelFontOpacityDouble
        )
        let fontStrokeColor = NSColor(
            hexString: MarkersExtractor.Settings.Defaults.imageLabelFontStrokeColor,
            alpha: imageLabelFontOpacityDouble
        )
        
        return MarkerLabelProperties(
            fontName: MarkersExtractor.Settings.Defaults.imageLabelFont,
            fontMaxSize: MarkersExtractor.Settings.Defaults.imageLabelFontMaxSize,
            fontColor: fontColor,
            fontStrokeColor: fontStrokeColor,
            fontStrokeWidth: MarkersExtractor.Settings.Defaults.imageLabelFontStrokeWidth,
            alignHorizontal: MarkersExtractor.Settings.Defaults.imageLabelAlignHorizontal,
            alignVertical: MarkersExtractor.Settings.Defaults.imageLabelAlignVertical
        )
    }
    
    init(using settings: MarkersExtractor.Settings) {
        fontName = settings.imageLabelFont
        fontMaxSize = settings.imageLabelFontMaxSize
        fontColor = NSColor(
            hexString: settings.imageLabelFontColor,
            alpha: settings.imageLabelFontOpacityDouble
        )
        fontStrokeColor = NSColor(
            hexString: settings.imageLabelFontStrokeColor,
            alpha: settings.imageLabelFontOpacityDouble
        )
        fontStrokeWidth = settings.imageLabelFontStrokeWidth
        alignHorizontal = settings.imageLabelAlignHorizontal
        alignVertical = settings.imageLabelAlignVertical
    }
}
