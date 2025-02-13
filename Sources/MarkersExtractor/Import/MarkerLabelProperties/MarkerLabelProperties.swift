//
//  MarkerLabelProperties.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit

// MARK: - MarkerLabelProperties

public struct MarkerLabelProperties {
    public let fontName: String
    public let fontMaxSize: Int
    public let fontColor: NSColor
    public let fontStrokeColor: NSColor
    public let fontStrokeWidth: Int?
    public let alignHorizontal: AlignHorizontal
    public let alignVertical: AlignVertical
}

extension MarkerLabelProperties: Equatable { }

extension MarkerLabelProperties: Hashable { }

extension MarkerLabelProperties: Sendable { }

// MARK: - Init (Internal)

extension MarkerLabelProperties {
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

// MARK: - Static Constructors

extension MarkerLabelProperties {
    public static func `default`() -> Self {
        let imageLabelFontOpacityDouble = Double(
            MarkersExtractor.Settings.Defaults
                .imageLabelFontOpacity
        ) / 100
        
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
}
