import AppKit
import Foundation

public struct MarkersExtractorSettings {
    public enum Defaults {
        public static let imageFormat: MarkerImageFormat = .png
        public static let imageQuality = 100
        public static let imageSizePercentGIF = 50
        public static let gifFPS = 10
        public static let gifSpan = 2
        public static let idNamingMode: MarkerIDMode = .projectTimecode
        public static let imageLabelFont = "Menlo-Regular"
        public static let imageLabelFontMaxSize = 30
        public static let imageLabelFontOpacity = 100
        public static let imageLabelFontColor = "#FFF"
        public static let imageLabelFontStrokeColor = "#000"
        public static let imageLabelAlignHorizontal = MarkerLabelProperties.AlignHorizontal.left
        public static let imageLabelAlignVertical = MarkerLabelProperties.AlignVertical.top
        public static let createDoneFile = false
    }

    let imageFormat: MarkerImageFormat
    let imageQuality: Int
    let imageWidth: Int?
    let imageHeight: Int?
    let imageSizePercent: Int?
    let gifFPS: Int
    let gifSpan: Int
    let idNamingMode: MarkerIDMode
    let imageLabels: [MarkerHeader]
    let imageLabelCopyright: String?
    let imageLabelFont: String
    let imageLabelFontMaxSize: Int
    let imageLabelFontOpacity: Int
    let imageLabelFontColor: String
    let imageLabelFontStrokeColor: String
    let imageLabelFontStrokeWidth: Int?
    let imageLabelAlignHorizontal: MarkerLabelProperties.AlignHorizontal
    let imageLabelAlignVertical: MarkerLabelProperties.AlignVertical
    let createDoneFile: Bool
    let fcpxmlPath: URL
    let outputDir: URL

    var xmlPath: URL {
        if fcpxmlPath.fileExtension == "fcpxmld" {
            return fcpxmlPath.appendingPathComponent("Info.fcpxml")
        }

        return fcpxmlPath
    }

    var mediaSearchPath: URL {
        fcpxmlPath.deletingLastPathComponent()
    }

    public init(
        imageFormat: MarkerImageFormat,
        imageQuality: Int,
        imageWidth: Int?,
        imageHeight: Int?,
        imageSizePercent: Int?,
        gifFPS: Int,
        gifSpan: Int,
        idNamingMode: MarkerIDMode,
        imageLabels: [MarkerHeader],
        imageLabelCopyright: String?,
        imageLabelFont: String,
        imageLabelFontMaxSize: Int,
        imageLabelFontOpacity: Int,
        imageLabelFontColor: String,
        imageLabelFontStrokeColor: String,
        imageLabelFontStrokeWidth: Int?,
        imageLabelAlignHorizontal: MarkerLabelProperties.AlignHorizontal,
        imageLabelAlignVertical: MarkerLabelProperties.AlignVertical,
        createDoneFile: Bool,
        fcpxmlPath: URL,
        outputDir: URL
    ) throws {
        self.imageFormat = imageFormat
        self.imageQuality = imageQuality
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageSizePercent = imageSizePercent
        self.gifFPS = gifFPS
        self.gifSpan = gifSpan
        self.idNamingMode = idNamingMode
        self.imageLabels = imageLabels
        self.imageLabelCopyright = imageLabelCopyright
        self.imageLabelFont = imageLabelFont
        self.imageLabelFontMaxSize = imageLabelFontMaxSize
        self.imageLabelFontOpacity = imageLabelFontOpacity
        self.imageLabelFontColor = imageLabelFontColor
        self.imageLabelFontStrokeColor = imageLabelFontStrokeColor
        self.imageLabelFontStrokeWidth = imageLabelFontStrokeWidth
        self.imageLabelAlignHorizontal = imageLabelAlignHorizontal
        self.imageLabelAlignVertical = imageLabelAlignVertical
        self.createDoneFile = createDoneFile
        self.fcpxmlPath = fcpxmlPath
        self.outputDir = outputDir

        try validate()
    }

    private func validate() throws {
        guard ["fcpxml", "fcpxmld"].contains(fcpxmlPath.fileExtension) else {
            throw MarkersExtractorError.validationError(
                "Unsupported input format '\(fcpxmlPath.path)'"
            )
        }

        if fcpxmlPath.fileExtension == "fcpxmld" {
            guard FileManager.default.fileExistsAndIsDirectory(fcpxmlPath.path) else {
                throw MarkersExtractorError.validationError(
                    "Path does not exist at '\(fcpxmlPath.path)'"
                )
            }
        }

        guard FileManager.default.fileExists(atPath: xmlPath.path) else {
            throw MarkersExtractorError.validationError("File does not exist at '\(xmlPath.path)'")
        }

        guard NSFont(name: imageLabelFont, size: 1) != nil else {
            throw MarkersExtractorError.validationError("Cannot use font '\(imageLabelFont)'")
        }

        if let imageLabelFontStrokeWidth = imageLabelFontStrokeWidth,
            imageLabelFontStrokeWidth < 0
        {
            throw MarkersExtractorError.validationError(
                "--label-stroke-width must be a positive integer or 0"
            )
        }

        guard (0...100).contains(imageLabelFontOpacity) else {
            throw MarkersExtractorError.validationError(
                "--label-font-opacity must be within 0...100 range"
            )
        }

        if let imageHeight = imageHeight, imageHeight <= 0 {
            throw MarkersExtractorError.validationError("--image-height must be a positive integer")
        }

        if let imageWidth = imageWidth, imageWidth <= 0 {
            throw MarkersExtractorError.validationError("--image-width must be a positive integer")
        }

        if let imageSizePercent = imageSizePercent, !(1...100).contains(imageSizePercent) {
            throw MarkersExtractorError.validationError(
                "--image-size-percent must be within 1...100 range"
            )
        }

        guard (0...100).contains(imageQuality) else {
            throw MarkersExtractorError.validationError(
                "--image-quality must be within 0...100 range"
            )
        }

        guard (1...50).contains(gifFPS) else {
            throw MarkersExtractorError.validationError("--gif-fps must be within 1...50 range")
        }
    }
}
