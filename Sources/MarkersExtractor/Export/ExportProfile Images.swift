//
//  ExportProfile Images.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

/// Generate animated images on disk.
/// For the time being, the only format supported is Animated GIF.
class AnimatedImagesWriter {
    let timecodes: OrderedDictionary<String, Timecode>
    let videoPath: URL
    let outputURL: URL
    let gifFPS: Double
    let gifSpan: TimeInterval
    let gifDimensions: CGSize?
    let imageFormat: MarkerImageFormat.Animated
    let imageLabelText: [String]
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger
    let exportProfileProgress: Progress?
    let progressUnitCount: Int64
    
    private var imageLabeler: ImageLabeler?
    private var filesProgress: Progress? = nil
    
    init(
        timecodes: OrderedDictionary<String, Timecode>,
        videoPath: URL,
        outputURL: URL,
        gifFPS: Double,
        gifSpan: TimeInterval,
        gifDimensions: CGSize?,
        imageFormat: MarkerImageFormat.Animated,
        imageLabelText: [String],
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil,
        exportProfileProgress: Progress? = nil,
        progressUnitCount: Int64 = 0
    ) {
        self.timecodes = timecodes
        self.videoPath = videoPath
        self.outputURL = outputURL
        self.gifFPS = gifFPS
        self.gifSpan = gifSpan
        self.gifDimensions = gifDimensions
        self.imageFormat = imageFormat
        self.imageLabelText = imageLabelText
        self.imageLabelProperties = imageLabelProperties
        self.logger = logger ?? Logger(label: "\(Self.self)")
        self.exportProfileProgress = exportProfileProgress
        self.progressUnitCount = progressUnitCount
    }
    
    func write() async throws {
        if !imageLabelText.isEmpty {
            imageLabeler = ImageLabeler(
                labelText: imageLabelText,
                labelProperties: imageLabelProperties,
                logger: logger
            )
        }
        
        if let exportProfileProgress {
            filesProgress = Progress(
                totalUnitCount: Int64(timecodes.count),
                parent: exportProfileProgress,
                pendingUnitCount: progressUnitCount
            )
        }
        
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for (imageName, timecode) in timecodes {
                taskGroup.addTask { [self] in
                    try await process(imageName: imageName, timecode: timecode)
                }
            }
        }
    }
    
    private func process(
        imageName: String,
        timecode: Timecode
    ) async throws {
        let outputURL = outputURL.appendingPathComponent(imageName)
        
        var delta = timecode
        delta.set(.realTime(seconds: gifSpan / 2), by: .clamping)
        
        let timeIn = timecode - delta
        let timeOut = timecode + delta
        let timeRange = timeIn ... timeOut
        
        imageLabeler?.nextText()
        
        let conversion = AnimatedImageExtractor.ConversionSettings(
            sourceMediaFile: videoPath,
            outputFolder: outputURL,
            timecodeRange: timeRange,
            dimensions: gifDimensions,
            outputFPS: gifFPS,
            imageFilter: imageLabeler?.labelImage,
            imageFormat: imageFormat
        )
        
        do {
            try AnimatedImageExtractor(conversion, logger: logger).convert()
        } catch let err as AnimatedImageExtractorError {
            throw MarkersExtractorError.extraction(.image(.animatedImage(err)))
        } catch {
            throw MarkersExtractorError.extraction(.image(.generic(
                "Error while generating animated thumbnail \(outputURL.lastPathComponent.quoted):"
                + " \(error.localizedDescription)"
            )))
        }
        
        filesProgress?.completedUnitCount += 1
    }
}

/// Generate still images on disk.
class ImagesWriter {
    let timecodes: OrderedDictionary<String, Timecode>
    let videoPath: URL
    let outputURL: URL
    let imageFormat: MarkerImageFormat.Still
    let imageJPGQuality: Double
    let imageDimensions: CGSize?
    let imageLabelText: [String]
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger?
    let exportProfileProgress: Progress?
    let progressUnitCount: Int64
    
    private var imageLabeler: ImageLabeler?
    
    init(
        timecodes: OrderedDictionary<String, Timecode>,
        videoPath: URL,
        outputURL: URL,
        imageFormat: MarkerImageFormat.Still,
        imageJPGQuality: Double,
        imageDimensions: CGSize?,
        imageLabelText: [String],
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil,
        exportProfileProgress: Progress? = nil,
        progressUnitCount: Int64 = 0
    ) {
        self.timecodes = timecodes
        self.videoPath = videoPath
        self.outputURL = outputURL
        self.imageFormat = imageFormat
        self.imageJPGQuality = imageJPGQuality
        self.imageDimensions = imageDimensions
        self.imageLabelText = imageLabelText
        self.imageLabelProperties = imageLabelProperties
        self.logger = logger ?? Logger(label: "\(Self.self)")
        self.exportProfileProgress = exportProfileProgress
        self.progressUnitCount = progressUnitCount
    }
    
    func write() throws {
        if !imageLabelText.isEmpty {
            imageLabeler = ImageLabeler(
                labelText: imageLabelText,
                labelProperties: imageLabelProperties,
                logger: logger
            )
        }
        
        let conversion = ImageExtractor.ConversionSettings(
            sourceMediaFile: videoPath,
            outputFolder: outputURL,
            timecodes: timecodes,
            frameFormat: imageFormat,
            jpgQuality: imageJPGQuality,
            dimensions: imageDimensions,
            imageFilter: imageLabeler?.labelImageNextText
        )
        
        let extractor = ImageExtractor(conversion, logger: logger)
        exportProfileProgress?.addChild(extractor.progress, withPendingUnitCount: progressUnitCount)
        
        do {
            try extractor.convert()
        } catch let err as ImageExtractorError {
            throw MarkersExtractorError.extraction(.image(.staticImage(err)))
        } catch {
            throw MarkersExtractorError.extraction(.image(.generic(
                "Error while generating images: \(error.localizedDescription)"
            )))
        }
    }
}
