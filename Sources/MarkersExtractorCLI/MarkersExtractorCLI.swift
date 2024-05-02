//
//  MarkersExtractorCLI.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import Foundation
import Logging
import MarkersExtractor
import DAWFileKit

@main
struct MarkersExtractorCLI: AsyncParsableCommand {
    // MARK: - Config
    
    static var configuration = CommandConfiguration(
        commandName: "markers-extractor",
        abstract: "Tool to extract markers from Final Cut Pro FCPXML/FCPXMLD.",
        discussion: "https://github.com/TheAcharya/MarkersExtractor",
        version: packageVersion
    )
    
    // MARK: - Arguments
    
    @Option(
        help: ArgumentHelp(
            "Metadata export format.",
            valueName: caseIterableValueString(for: ExportProfileFormat.self)
        )
    )
    var exportFormat: ExportProfileFormat = MarkersExtractor.Settings.Defaults.exportFormat
    
    @Flag(help: ArgumentHelp("Enable output of timecode subframes."))
    var enableSubframes: Bool = MarkersExtractor.Settings.Defaults.enableSubframes
    
    @Option(
        help: ArgumentHelp(
            "Annotations to import. If captions are used, their start timecode determines their position.",
            valueName: caseIterableValueString(for: MarkersSource.self)
        )
    )
    var markersSource: MarkersSource = MarkersExtractor.Settings.Defaults.markersSource
    
    @Flag(
        help: ArgumentHelp(
            "For chapter markers, use their thumbnail pin position for thumbnail image generation."
        )
    )
    var useChapterMarkerThumbnails: Bool = MarkersExtractor.Settings.Defaults.useChapterMarkerThumbnails
    
    @Option(
        name: [.customLong("exclude-role")],
        help: ArgumentHelp(
            "Exclude markers with a specified role. This argument can be supplied more than once to apply multiple role exclusions.",
            valueName: "name"
        )
    )
    var excludeRoles: [String] = []
    
    @Flag(
        name: [.customLong("include-disabled")],
        help: ArgumentHelp(
            "Include markers on disabled clips. By default, disabled clips are ignored."
        )
    )
    var includeDisabled: Bool = MarkersExtractor.Settings.Defaults.includeDisabled
    
    @Option(
        help: ArgumentHelp(
            "Marker thumb image format. 'gif' is animated and additional options can be specified with --gif-fps and --gif-span.",
            valueName: caseIterableValueString(for: MarkerImageFormat.self)
        )
    )
    var imageFormat: MarkerImageFormat = MarkersExtractor.Settings.Defaults.imageFormat
    
    @Option(
        help: ArgumentHelp(
            "Image quality percent for JPG.",
            valueName: "\(MarkersExtractor.Settings.Validation.imageQuality)"
        )
    )
    var imageQuality: Int = MarkersExtractor.Settings.Defaults.imageQuality
    
    @Option(help: ArgumentHelp("Limit image width keeping aspect ratio.", valueName: "w"))
    var imageWidth: Int?
    
    @Option(help: ArgumentHelp("Limit image height keeping aspect ratio.", valueName: "h"))
    var imageHeight: Int?
    
    @Option(
        help: ArgumentHelp(
            "Limit image size to % keeping aspect ratio. (default for GIF: \(MarkersExtractor.Settings.Defaults.imageSizePercentGIF))",
            valueName: "\(MarkersExtractor.Settings.Validation.imageSizePercent)"
        )
    )
    var imageSizePercent: Int?
    
    @Option(
        help: ArgumentHelp(
            "GIF frame rate.",
            valueName: "\(MarkersExtractor.Settings.Validation.outputFPS)"
        )
    )
    var gifFPS: Double = MarkersExtractor.Settings.Defaults.gifFPS
    
    @Option(help: ArgumentHelp("GIF capture span around marker.", valueName: "sec"))
    var gifSpan: TimeInterval = MarkersExtractor.Settings.Defaults.gifSpan
    
    @Option(
        help: ArgumentHelp(
            "Marker naming mode. This affects Marker IDs and image filenames.",
            valueName: caseIterableValueString(for: MarkerIDMode.self)
        )
    )
    var idNamingMode: MarkerIDMode = MarkersExtractor.Settings.Defaults.idNamingMode
    
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
    
    @Option(
        help: ArgumentHelp(
            "Path including filename to create a JSON result file. If this option is not passed, it won't be created.",
            valueName: "path"
        ),
        transform: URL.init(fileURLWithPath:)
    )
    var resultFilePath: URL? = MarkersExtractor.Settings.Defaults.resultFilePath
    
    @Option(
        name: [.customLong("folder-format")],
        help: ArgumentHelp(
            "Output folder name format.",
            valueName: caseIterableValueString(for: ExportFolderFormat.self)
        )
    )
    var exportFolderFormat: ExportFolderFormat = MarkersExtractor.Settings.Defaults.exportFolderFormat
    
    @Option(help: "Log file path.", transform: URL.init(fileURLWithPath:))
    var log: URL?
    
    @Option(
        help: ArgumentHelp(
            "Log level.",
            valueName: caseIterableValueString(for: Logger.Level.self)
        )
    )
    var logLevel: Logger.Level = .info
    
    @Flag(name: [.customLong("quiet")], help: "Disable log.")
    var logQuiet = false
    
    @Flag(name: [.customLong("no-progress")], help: "Disable progress logging.")
    var noProgressLogging = false
    
    @Option(
        name: [.customLong("media-search-path")],
        help: ArgumentHelp(
            "Media search path. This argument can be supplied more than once to use multiple paths. (default: same folder as fcpxml(d))",
            valueName: "path"
        ),
        transform: URL.init(fileURLWithPath:)
    )
    var mediaSearchPaths: [URL] = []
    
    @Flag(
        name: [.customLong("no-media")],
        help: "Bypass media. No thumbnails will be generated."
    )
    var noMedia: Bool = MarkersExtractor.Settings.Defaults.noMedia
    
    @Argument(help: "Input FCPXML file / FCPXMLD bundle.", transform: URL.init(fileURLWithPath:))
    var fcpxmlPath: URL
    
    @Argument(help: "Output directory.", transform: URL.init(fileURLWithPath:))
    var outputDir: URL
    
    // MARK: - Protocol Method Implementations
    
    mutating func validate() throws {
        if let log {
            if FileManager.default.fileExists(atPath: log.path) {
                // check that existing file is writable
                if !FileManager.default.isWritableFile(atPath: log.path) {
                    throw ValidationError("Cannot write log file at \(log.path.quoted)")
                }
            }
        }
        
        if imageFormat == .animated(.gif), imageSizePercent == nil {
            imageSizePercent = MarkersExtractor.Settings.Defaults.imageSizePercentGIF
        }
    }
    
    mutating func run() async throws {
        let settings: MarkersExtractor.Settings
        
        do {
            let fcpxml = try FCPXMLFile(at: fcpxmlPath)
            let mediaSearchPaths = mediaSearchPaths.isEmpty
                ? MarkersExtractor.Settings.Defaults.mediaSearchPaths(from: fcpxml)
                : mediaSearchPaths
            
            settings = try MarkersExtractor.Settings(
                fcpxml: fcpxml,
                outputDir: outputDir,
                noMedia: noMedia,
                mediaSearchPaths: mediaSearchPaths,
                exportFormat: exportFormat,
                enableSubframes: enableSubframes,
                markersSource: markersSource,
                useChapterMarkerThumbnails: useChapterMarkerThumbnails,
                excludeRoles: Set(excludeRoles),
                includeDisabled: includeDisabled,
                imageFormat: imageFormat,
                imageQuality: imageQuality,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                imageSizePercent: imageSizePercent,
                gifFPS: gifFPS,
                gifSpan: gifSpan,
                idNamingMode: idNamingMode,
                imageLabels: imageLabels,
                imageLabelCopyright: imageLabelCopyright,
                imageLabelFont: imageLabelFont,
                imageLabelFontMaxSize: imageLabelFontMaxSize,
                imageLabelFontOpacity: imageLabelFontOpacity,
                imageLabelFontColor: imageLabelFontColor,
                imageLabelFontStrokeColor: imageLabelFontStrokeColor,
                imageLabelFontStrokeWidth: imageLabelFontStrokeWidth,
                imageLabelAlignHorizontal: imageLabelAlignHorizontal,
                imageLabelAlignVertical: imageLabelAlignVertical,
                imageLabelHideNames: imageLabelHideNames,
                resultFilePath: resultFilePath,
                exportFolderFormat: exportFolderFormat
            )
        } catch let err as MarkersExtractorError {
            throw ValidationError(err.localizedDescription)
        }
        
        let extractorLoggerLabel = "MarkersExtractor"
        let extractorLogger = Logger(label: extractorLoggerLabel) { label in
            fileAndConsoleLogFactory(label: extractorLoggerLabel, logLevel: logLevel, logFile: log)
        }
        
        let extractor = MarkersExtractor(settings: settings, logger: extractorLogger)
        
        if !noProgressLogging {
            let progressLoggerLabel = "Progress"
            let progressLogger = Logger(label: progressLoggerLabel) { label in
                consoleLogFactory(label: progressLoggerLabel, logLevel: logLevel)
            }
            _progressLogging = ProgressLogging(to: progressLogger, progress: extractor.progress)
        }
        
        // can ignore return data from extract(), as it merely contains result file content
        // (same content that is written to the result file)
        // and is mainly provided to consumers of the library to use. for the CLI we don't need it.
        _ = try await extractor.extract()
    }
    
    private var _progressLogging: ProgressLogging?
}
