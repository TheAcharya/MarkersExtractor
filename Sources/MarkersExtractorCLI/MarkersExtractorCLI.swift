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

// MARK: - Main Command

@main
struct MarkersExtractorCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "markers-extractor",
        abstract: "Tool to extract markers from Final Cut Pro FCPXML/FCPXMLD.",
        discussion: "https://github.com/TheAcharya/MarkersExtractor",
        version: packageVersion,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong
    )
    
    // MARK: - General Options
    
    @OptionGroup(title: "GENERAL")
    var generalOptions: GeneralOptions
    
    // MARK: - Image Options
    
    @OptionGroup(title: "IMAGE")
    var imageOptions: ImageOptions
    
    // MARK: - Label Options
    
    @OptionGroup(title: "LABEL")
    var labelOptions: LabelOptions
    
    // MARK: - Log Options
    
    @OptionGroup(title: "LOG")
    var logOptions: LogOptions
    
    // MARK: - Media Options
    
    @OptionGroup(title: "MEDIA")
    var mediaOptions: MediaOptions
    
    // MARK: - Required Arguments
    
    @Argument(help: "Input FCPXML file / FCPXMLD bundle.", transform: URL.init(fileURLWithPath:))
    var fcpxmlPath: URL
    
    @Argument(help: "Output directory.", transform: URL.init(fileURLWithPath:))
    var outputDir: URL
    
    // MARK: - Internal
    
    private var _progressLogging: ProgressLogging?
}

// MARK: - AsyncParsableCommand Implementation

extension MarkersExtractorCLI {
    mutating func validate() throws {
        if let log = logOptions.log {
            if FileManager.default.fileExists(atPath: log.path) {
                // check that existing file is writable
                if !FileManager.default.isWritableFile(atPath: log.path) {
                    throw ValidationError("Cannot write log file at \(log.path.quoted)")
                }
            }
        }
        
        if imageOptions.imageFormat == .animated(.gif), imageOptions.imageSizePercent == nil {
            imageOptions.imageSizePercent = MarkersExtractor.Settings.Defaults.imageSizePercentGIF
        }
    }
    
    mutating func run() async throws {
        let settings: MarkersExtractor.Settings
        
        do {
            let fcpxml = try FCPXMLFile(at: fcpxmlPath)
            let mediaSearchPaths = mediaOptions.mediaSearchPaths.isEmpty
            ? MarkersExtractor.Settings.Defaults.mediaSearchPaths(from: fcpxml)
            : mediaOptions.mediaSearchPaths
            
            settings = try MarkersExtractor.Settings(
                fcpxml: fcpxml,
                outputDir: outputDir,
                noMedia: mediaOptions.noMedia,
                mediaSearchPaths: mediaSearchPaths,
                exportFormat: generalOptions.exportFormat,
                enableSubframes: generalOptions.enableSubframes,
                markersSource: generalOptions.markersSource,
                useChapterMarkerThumbnails: generalOptions.useChapterMarkerThumbnails,
                excludeRoles: Set(generalOptions.excludeRoles),
                includeDisabled: generalOptions.includeDisabled,
                imageFormat: imageOptions.imageFormat,
                imageQuality: imageOptions.imageQuality,
                imageWidth: imageOptions.imageWidth,
                imageHeight: imageOptions.imageHeight,
                imageSizePercent: imageOptions.imageSizePercent,
                gifFPS: imageOptions.gifFPS,
                gifSpan: imageOptions.gifSpan,
                idNamingMode: generalOptions.idNamingMode,
                imageLabels: labelOptions.imageLabels,
                imageLabelCopyright: labelOptions.imageLabelCopyright,
                imageLabelFont: labelOptions.imageLabelFont,
                imageLabelFontMaxSize: labelOptions.imageLabelFontMaxSize,
                imageLabelFontOpacity: labelOptions.imageLabelFontOpacity,
                imageLabelFontColor: labelOptions.imageLabelFontColor,
                imageLabelFontStrokeColor: labelOptions.imageLabelFontStrokeColor,
                imageLabelFontStrokeWidth: labelOptions.imageLabelFontStrokeWidth,
                imageLabelAlignHorizontal: labelOptions.imageLabelAlignHorizontal,
                imageLabelAlignVertical: labelOptions.imageLabelAlignVertical,
                imageLabelHideNames: labelOptions.imageLabelHideNames,
                resultFilePath: logOptions.resultFilePath,
                exportFolderFormat: generalOptions.exportFolderFormat
            )
        } catch let err as MarkersExtractorError {
            throw ValidationError(err.localizedDescription)
        }
        
        let extractorLoggerLabel = "MarkersExtractor"
        let extractorLoggerHandler = await LogFactory.shared.fileAndConsoleLogFactory(label: extractorLoggerLabel, logLevel: logOptions.logLevel, logFile: logOptions.log)
        let extractorLogger = Logger(label: extractorLoggerLabel) { label in
            extractorLoggerHandler
        }
        
        let extractor = MarkersExtractor(settings: settings, logger: extractorLogger)
        
        if !logOptions.noProgressLogging {
            let progressLoggerLabel = "Progress"
            let progressLoggerHandler = await LogFactory.shared.consoleLogFactory(label: progressLoggerLabel, logLevel: logOptions.logLevel)
            let progressLogger = Logger(label: progressLoggerLabel) { label in
                progressLoggerHandler
            }
            _progressLogging = await ProgressLogging(to: progressLogger, progress: extractor.progress)
        }
        
        // can ignore return data from extract(), as it merely contains result file content
        // (same content that is written to the result file)
        // and is mainly provided to consumers of the library to use. for the CLI we don't need it.
        _ = try await extractor.extract()
    }
}
