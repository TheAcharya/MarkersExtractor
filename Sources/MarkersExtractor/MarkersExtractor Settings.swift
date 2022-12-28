import AppKit
import Foundation

extension MarkersExtractor {
    public struct Settings {
        public enum Defaults {
            public static let exportFormat: ExportProfileFormat = .csv2Notion
            public static let imageFormat: MarkerImageFormat = .still(.png)
            public static let imageQuality = 100
            public static let imageWidth: Int? = nil
            public static let imageHeight: Int? = nil
            public static let imageSizePercent: Int? = 100
            public static let imageSizePercentGIF = 50
            public static let gifFPS: Double = 10.0
            public static let gifSpan: TimeInterval = 2
            public static let idNamingMode: MarkerIDMode = .projectTimecode
            public static let imageLabels: [CSVExportProfile.Field] = []
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
            public static func mediaSearchPaths(from fcpxml: FCPXMLFile) -> [URL] {
                [fcpxml.defaultMediaSearchPath].compactMap { $0 }
            }
            public static let doneFilename = "done.txt"
        }
        
        public enum Validation {
            public static let imageSizePercent = 1 ... 100
            public static let imageQuality = 0 ... 100
            public static let gifFPS = 0.1 ... 60.0
            public static let imageLabelFontOpacity = 0 ... 100
        }
        
        public var exportFormat: ExportProfileFormat
        public var imageFormat: MarkerImageFormat
        public var imageQuality: Int
        public var imageWidth: Int?
        public var imageHeight: Int?
        public var imageSizePercent: Int?
        public var gifFPS: Double
        public var gifSpan: TimeInterval
        public var idNamingMode: MarkerIDMode
        public var imageLabels: [CSVExportProfile.Field]
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
        public var mediaSearchPaths: [URL]
        public var outputDir: URL
        public var doneFilename: String
        
        @available(*, deprecated, message: "This should be removed and refactored.")
        var xmlPath: URL? {
            fcpxml.xmlPath
        }
        
        /// Initialize with defaults for defaultable parameters.
        public init(
            fcpxml: FCPXMLFile,
            outputDir: URL
        ) throws {
            self.exportFormat = Defaults.exportFormat
            self.imageFormat = Defaults.imageFormat
            self.imageQuality = Defaults.imageQuality
            self.imageWidth = Defaults.imageWidth
            self.imageHeight = Defaults.imageHeight
            self.imageSizePercent = Defaults.imageSizePercent
            self.gifFPS = Defaults.gifFPS
            self.gifSpan = Defaults.gifSpan
            self.idNamingMode = Defaults.idNamingMode
            self.imageLabels = Defaults.imageLabels
            self.imageLabelCopyright = Defaults.imageLabelCopyright
            self.imageLabelFont = Defaults.imageLabelFont
            self.imageLabelFontMaxSize = Defaults.imageLabelFontMaxSize
            self.imageLabelFontOpacity = Defaults.imageLabelFontOpacity
            self.imageLabelFontColor = Defaults.imageLabelFontColor
            self.imageLabelFontStrokeColor = Defaults.imageLabelFontStrokeColor
            self.imageLabelFontStrokeWidth = Defaults.imageLabelFontStrokeWidth
            self.imageLabelAlignHorizontal = Defaults.imageLabelAlignHorizontal
            self.imageLabelAlignVertical = Defaults.imageLabelAlignVertical
            self.imageLabelHideNames = Defaults.imageLabelHideNames
            self.createDoneFile = Defaults.createDoneFile
            self.doneFilename = Defaults.doneFilename
            self.fcpxml = fcpxml
            self.mediaSearchPaths = Defaults.mediaSearchPaths(from: fcpxml)
            self.outputDir = outputDir
            
            try validate()
        }
        
        public init(
            exportFormat: ExportProfileFormat,
            imageFormat: MarkerImageFormat,
            imageQuality: Int,
            imageWidth: Int?,
            imageHeight: Int?,
            imageSizePercent: Int?,
            gifFPS: Double,
            gifSpan: TimeInterval,
            idNamingMode: MarkerIDMode,
            imageLabels: [CSVExportProfile.Field],
            imageLabelCopyright: String?,
            imageLabelFont: String,
            imageLabelFontMaxSize: Int,
            imageLabelFontOpacity: Int,
            imageLabelFontColor: String,
            imageLabelFontStrokeColor: String,
            imageLabelFontStrokeWidth: Int?,
            imageLabelAlignHorizontal: MarkerLabelProperties.AlignHorizontal,
            imageLabelAlignVertical: MarkerLabelProperties.AlignVertical,
            imageLabelHideNames: Bool,
            createDoneFile: Bool,
            doneFilename: String,
            fcpxml: FCPXMLFile,
            mediaSearchPaths: [URL],
            outputDir: URL
        ) throws {
            self.exportFormat = exportFormat
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
            self.imageLabelHideNames = imageLabelHideNames
            self.createDoneFile = createDoneFile
            self.doneFilename = doneFilename
            self.fcpxml = fcpxml
            self.mediaSearchPaths = mediaSearchPaths
            self.outputDir = outputDir
            
            try validate()
        }
        
        private func validate() throws {
            if let fcpxmlPath = fcpxml.url {
                guard ["fcpxml", "fcpxmld"].contains(fcpxmlPath.fileExtension) else {
                    throw MarkersExtractorError.validationError(
                        "Unsupported input format \(fcpxmlPath.path.quoted)."
                    )
                }
                
                if fcpxmlPath.fileExtension == "fcpxmld" {
                    guard FileManager.default.fileExistsAndIsDirectory(fcpxmlPath.path) else {
                        throw MarkersExtractorError.validationError(
                            "Path does not exist at \(fcpxmlPath.path.quoted)."
                        )
                    }
                }
                
                guard fcpxmlPath.exists else {
                    throw MarkersExtractorError.validationError("File does not exist at \(fcpxmlPath.path.quoted).")
                }
            }
            
            guard NSFont(name: imageLabelFont, size: 1) != nil else {
                throw MarkersExtractorError.validationError("Cannot use font \(imageLabelFont.quoted).")
            }
            
            if let imageLabelFontStrokeWidth = imageLabelFontStrokeWidth,
               imageLabelFontStrokeWidth < 0
            {
                throw MarkersExtractorError.validationError(
                    "--label-stroke-width must be a positive integer or 0."
                )
            }
            
            guard Validation.imageLabelFontOpacity.contains(imageLabelFontOpacity) else {
                throw MarkersExtractorError.validationError(
                    "--label-font-opacity must be within \(Validation.imageLabelFontOpacity) range."
                )
            }
            
            if let imageHeight = imageHeight, imageHeight <= 0 {
                throw MarkersExtractorError.validationError("--image-height must be a positive integer.")
            }
            
            if let imageWidth = imageWidth, imageWidth <= 0 {
                throw MarkersExtractorError.validationError("--image-width must be a positive integer.")
            }
            
            if let imageSizePercent = imageSizePercent, !Validation.imageSizePercent.contains(imageSizePercent) {
                throw MarkersExtractorError.validationError(
                    "--image-size-percent must be within \(Validation.imageSizePercent) range."
                )
            }
            
            guard Validation.imageQuality.contains(imageQuality) else {
                throw MarkersExtractorError.validationError(
                    "--image-quality must be within \(Validation.imageQuality) range."
                )
            }
            
            guard Validation.gifFPS.contains(gifFPS) else {
                throw MarkersExtractorError.validationError("--gif-fps must be within \(Validation.gifFPS) range.")
            }
        }
    }
}
