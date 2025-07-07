//
//  MarkersExtractorCLI+Label.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import Foundation
import Logging
import MarkersExtractor
import DAWFileKit

extension MarkersExtractorCLI {
    struct LabelOptions: ParsableArguments {
        @Option(
            name: [.customLong("label")],
            help: ArgumentHelp(
                "Label to overlay on thumb images. This argument can be supplied more than once to apply multiple labels.",
                valueName: caseIterableValueString(for: ExportField.self)
            )
        )
        var imageLabels: [ExportField] = []
        
        @Option(
            name: [.customLong("label-copyright")],
            help: ArgumentHelp(
                "Copyright label. Will be appended after other labels.",
                valueName: "text"
            )
        )
        var imageLabelCopyright: String?
        
        @Option(
            name: [.customLong("label-font")],
            help: ArgumentHelp("Font for image labels.", valueName: "name")
        )
        var imageLabelFont: String = MarkersExtractor.Settings.Defaults.imageLabelFont
        
        @Option(
            name: [.customLong("label-font-size")],
            help: ArgumentHelp(
                "Maximum font size for image labels, font size is automatically reduced to fit all labels.",
                valueName: "pt"
            )
        )
        var imageLabelFontMaxSize: Int = MarkersExtractor.Settings.Defaults.imageLabelFontMaxSize
        
        @Option(
            name: [.customLong("label-opacity")],
            help: ArgumentHelp(
                "Label opacity percent",
                valueName: "\(MarkersExtractor.Settings.Validation.imageLabelFontOpacity)"
            )
        )
        var imageLabelFontOpacity: Int = MarkersExtractor.Settings.Defaults.imageLabelFontOpacity
        
        @Option(
            name: [.customLong("label-font-color")],
            help: ArgumentHelp("Label font color", valueName: "#RRGGBB / #RGB")
        )
        var imageLabelFontColor: String = MarkersExtractor.Settings.Defaults.imageLabelFontColor
        
        @Option(
            name: [.customLong("label-stroke-color")],
            help: ArgumentHelp("Label stroke color", valueName: "#RRGGBB / #RGB")
        )
        var imageLabelFontStrokeColor: String = MarkersExtractor.Settings.Defaults
            .imageLabelFontStrokeColor
        
        @Option(
            name: [.customLong("label-stroke-width")],
            help: ArgumentHelp("Label stroke width, 0 to disable. (default: auto)", valueName: "w")
        )
        var imageLabelFontStrokeWidth: Int?
        
        @Option(
            name: [.customLong("label-align-horizontal")],
            help: ArgumentHelp(
                "Horizontal alignment of image labels.",
                valueName: caseIterableValueString(for: MarkerLabelProperties.AlignHorizontal.self)
            )
        )
        var imageLabelAlignHorizontal: MarkerLabelProperties.AlignHorizontal = MarkersExtractor.Settings
            .Defaults.imageLabelAlignHorizontal
        
        @Option(
            name: [.customLong("label-align-vertical")],
            help: ArgumentHelp(
                "Vertical alignment of image labels.",
                valueName: caseIterableValueString(for: MarkerLabelProperties.AlignVertical.self)
            )
        )
        var imageLabelAlignVertical: MarkerLabelProperties.AlignVertical = MarkersExtractor.Settings
            .Defaults.imageLabelAlignVertical
        
        @Flag(
            name: [.customLong("label-hide-names")],
            help: ArgumentHelp("Hide names of image labels.")
        )
        var imageLabelHideNames: Bool = MarkersExtractor.Settings.Defaults.imageLabelHideNames
    }
}
