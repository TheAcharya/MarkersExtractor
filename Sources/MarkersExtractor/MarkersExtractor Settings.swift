//
//  MarkersExtractor Settings.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
import Foundation

extension MarkersExtractor {
    public struct Settings {
        public enum Defaults {
            public static let exportFormat: ExportProfileFormat = .notion
            public static let enableSubframes = false
            public static let imageFormat: MarkerImageFormat = .still(.png)
            public static let imageQuality = 85
            public static let imageWidth: Int? = nil
            public static let imageHeight: Int? = nil
            public static let imageSizePercent: Int? = 100
            public static let imageSizePercentGIF = 50
            public static let gifFPS: Double = 10.0
            public static let gifSpan: TimeInterval = 2
            public static let idNamingMode: MarkerIDMode = .projectTimecode
            public static let includeOutsideClipBoundaries = false
            public static let excludeRoleType: MarkerRoleType? = nil
            public static let imageLabels: [ExportField] = []
            public static let imageLabelCopyright: String? = nil
            public static let imageLabelFont = "Menlo-Regular"
            public static let imageLabelFontMaxSize = 30
            public static let imageLabelFontOpacity = 100
            public static let imageLabelFontColor = "#FFF"
            public static let imageLabelFontStrokeColor = "#000"
            public static let imageLabelFontStrokeWidth: Int? = nil
            public static let imageLabelAlignHorizontal: MarkerLabelProperties.AlignHorizontal = .left
            public static let imageLabelAlignVertical: MarkerLabelProperties.AlignVertical = .top
            public static let imageLabelHideNames = false
            public static let createDoneFile = false
            public static let exportFolderFormat: ExportFolderFormat = .medium
            public static let noMedia: Bool = false
            public static func mediaSearchPaths(from fcpxml: FCPXMLFile) -> [URL] {
                [fcpxml.defaultMediaSearchPath].compactMap { $0 }
            }

            public static let doneFilename = "done.json"
        }
        
        public enum Validation {
            public static let imageSizePercent = 1 ... 100
            public static let imageQuality = 0 ... 100
            public static let outputFPS = 0.1 ... 60.0
            public static let imageLabelFontOpacity = 0 ... 100
        }
        
        public var exportFormat: ExportProfileFormat
        public var enableSubframes: Bool
        public var imageFormat: MarkerImageFormat
        public var imageQuality: Int
        public var imageWidth: Int?
        public var imageHeight: Int?
        public var imageSizePercent: Int?
        public var gifFPS: Double
        public var gifSpan: TimeInterval
        public var idNamingMode: MarkerIDMode
        public var includeOutsideClipBoundaries: Bool
        public var excludeRoleType: MarkerRoleType?
        public var imageLabels: [ExportField]
        public var imageLabelCopyright: String?
        public var imageLabelFont: String
        public var imageLabelFontMaxSize: Int
        public var imageLabelFontOpacity: Int
        public var imageLabelFontColor: String
        public var imageLabelFontStrokeColor: String
        public var imageLabelFontStrokeWidth: Int?
        public var imageLabelAlignHorizontal: MarkerLabelProperties.AlignHorizontal
        public var imageLabelAlignVertical: MarkerLabelProperties.AlignVertical
        public var imageLabelHideNames: Bool
        public var createDoneFile: Bool
        public var fcpxml: FCPXMLFile
        public var noMedia: Bool
        public var mediaSearchPaths: [URL]
        public var outputDir: URL
        public var doneFilename: String
        public var exportFolderFormat: ExportFolderFormat
        
        public init(
            fcpxml: FCPXMLFile,
            outputDir: URL,
            noMedia: Bool = Defaults.noMedia,
            mediaSearchPaths: [URL]? = nil,
            exportFormat: ExportProfileFormat = Defaults.exportFormat,
            enableSubframes: Bool = Defaults.enableSubframes,
            imageFormat: MarkerImageFormat = Defaults.imageFormat,
            imageQuality: Int = Defaults.imageQuality,
            imageWidth: Int? = Defaults.imageWidth,
            imageHeight: Int? = Defaults.imageHeight,
            imageSizePercent: Int? = Defaults.imageSizePercent,
            gifFPS: Double = Defaults.gifFPS,
            gifSpan: TimeInterval = Defaults.gifSpan,
            idNamingMode: MarkerIDMode = Defaults.idNamingMode,
            includeOutsideClipBoundaries: Bool = Defaults.includeOutsideClipBoundaries,
            excludeRoleType: MarkerRoleType? = Defaults.excludeRoleType,
            imageLabels: [ExportField] = Defaults.imageLabels,
            imageLabelCopyright: String? = Defaults.imageLabelCopyright,
            imageLabelFont: String = Defaults.imageLabelFont,
            imageLabelFontMaxSize: Int = Defaults.imageLabelFontMaxSize,
            imageLabelFontOpacity: Int = Defaults.imageLabelFontOpacity,
            imageLabelFontColor: String = Defaults.imageLabelFontColor,
            imageLabelFontStrokeColor: String = Defaults.imageLabelFontStrokeColor,
            imageLabelFontStrokeWidth: Int? = Defaults.imageLabelFontStrokeWidth,
            imageLabelAlignHorizontal: MarkerLabelProperties.AlignHorizontal =
                Defaults.imageLabelAlignHorizontal,
            imageLabelAlignVertical: MarkerLabelProperties.AlignVertical =
                Defaults.imageLabelAlignVertical,
            imageLabelHideNames: Bool = Defaults.imageLabelHideNames,
            createDoneFile: Bool = Defaults.createDoneFile,
            doneFilename: String = Defaults.doneFilename,
            exportFolderFormat: ExportFolderFormat = Defaults.exportFolderFormat
        ) throws {
            self.fcpxml = fcpxml
            self.outputDir = outputDir
            
            self.noMedia = noMedia
            self.mediaSearchPaths = mediaSearchPaths ?? Defaults.mediaSearchPaths(from: fcpxml)
            self.exportFormat = exportFormat
            self.enableSubframes = enableSubframes
            self.imageFormat = imageFormat
            self.imageQuality = imageQuality
            self.imageWidth = imageWidth
            self.imageHeight = imageHeight
            self.imageSizePercent = imageSizePercent
            self.gifFPS = gifFPS
            self.gifSpan = gifSpan
            self.idNamingMode = idNamingMode
            self.includeOutsideClipBoundaries = includeOutsideClipBoundaries
            self.excludeRoleType = excludeRoleType
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
            self.imageLabelHideNames = imageLabelHideNames
            self.createDoneFile = createDoneFile
            self.doneFilename = doneFilename
            self.exportFolderFormat = exportFolderFormat
            
            try validate()
        }
        
        /// Validate settings parameters.
        /// Throws an error if validation fails.
        public func validate() throws {
            if let fcpxmlPath = fcpxml.baseURL {
                guard ["fcpxml", "fcpxmld"].contains(fcpxmlPath.fileExtension) else {
                    throw MarkersExtractorError.validation(
                        .unsupportedFileFormat(atPath: fcpxmlPath.path)
                    )
                }
                
                if fcpxmlPath.fileExtension == "fcpxmld" {
                    guard FileManager.default.fileIsDirectory(fcpxmlPath.path) else {
                        throw MarkersExtractorError.validation(
                            .fcpxmldIsNotADirectory(atPath: fcpxmlPath.path)
                        )
                    }
                }
                
                guard fcpxmlPath.exists else {
                    throw MarkersExtractorError.validation(
                        .fileNotExists(atPath: fcpxmlPath.path)
                    )
                }
            }
            
            // if media is bypassed, none of the thumbnail parameters will be used.
            if !noMedia {
                guard NSFont(name: imageLabelFont, size: 1) != nil else {
                    throw MarkersExtractorError.validation(
                        .fontNotUsable(imageLabelFont)
                    )
                }
                
                if let imageLabelFontStrokeWidth = imageLabelFontStrokeWidth,
                   imageLabelFontStrokeWidth < 0
                {
                    throw MarkersExtractorError.validation(
                        .invalidImageLabelStrokeWidth
                    )
                }
                
                guard Validation.imageLabelFontOpacity.contains(imageLabelFontOpacity) else {
                    throw MarkersExtractorError.validation(
                        .invalidImageLabelFontOpacity
                    )
                }
                
                if let imageHeight = imageHeight, imageHeight <= 0 {
                    throw MarkersExtractorError.validation(
                        .invalidImageHeight
                    )
                }
                
                if let imageWidth = imageWidth, imageWidth <= 0 {
                    throw MarkersExtractorError.validation(
                        .invalidImageWidth
                    )
                }
                
                if let imageSizePercent = imageSizePercent,
                   !Validation.imageSizePercent.contains(imageSizePercent)
                {
                    throw MarkersExtractorError.validation(
                        .invalidImageSizePercent
                    )
                }
                
                guard Validation.imageQuality.contains(imageQuality) else {
                    throw MarkersExtractorError.validation(
                        .invalidImageQuality
                    )
                }
                
                guard Validation.outputFPS.contains(gifFPS) else {
                    throw MarkersExtractorError.validation(
                        .invalidOutputFPS
                    )
                }
            }
        }
    }
}
