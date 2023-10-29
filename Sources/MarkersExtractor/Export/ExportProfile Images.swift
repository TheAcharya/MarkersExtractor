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

struct ImageDescriptor {
    let timecode: Timecode
    let name: String
    let label: String?
}

/// Generate animated images on disk.
/// For the time being, the only format supported is Animated GIF.
class AnimatedImagesWriter {
    let descriptors: [ImageDescriptor]
    let videoPath: URL
    let outputURL: URL
    let gifFPS: Double
    let gifSpan: TimeInterval
    let gifDimensions: CGSize?
    let imageFormat: MarkerImageFormat.Animated
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger
    let exportProfileProgress: Progress?
    let progressUnitCount: Int64
    
    private var imageLabeler: ImageLabeler
    private var filesProgress: Progress? = nil
    
    init(
        descriptors: [ImageDescriptor],
        videoPath: URL,
        outputURL: URL,
        gifFPS: Double,
        gifSpan: TimeInterval,
        gifDimensions: CGSize?,
        imageFormat: MarkerImageFormat.Animated,
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil,
        exportProfileProgress: Progress? = nil,
        progressUnitCount: Int64 = 0
    ) {
        self.descriptors = descriptors
        self.videoPath = videoPath
        self.outputURL = outputURL
        self.gifFPS = gifFPS
        self.gifSpan = gifSpan
        self.gifDimensions = gifDimensions
        self.imageFormat = imageFormat
        self.imageLabelProperties = imageLabelProperties
        self.logger = logger ?? Logger(label: "\(Self.self)")
        self.exportProfileProgress = exportProfileProgress
        self.progressUnitCount = progressUnitCount
        
        imageLabeler = ImageLabeler(
            labelProperties: imageLabelProperties,
            logger: logger
        )
    }
    
    func write() async throws {
        if let exportProfileProgress {
            filesProgress = Progress(
                totalUnitCount: Int64(descriptors.count),
                parent: exportProfileProgress,
                pendingUnitCount: progressUnitCount
            )
        }
        
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for descriptor in descriptors {
                taskGroup.addTask { [self] in
                    try await process(descriptor: descriptor)
                }
            }
        }
    }
    
    private func process(descriptor: ImageDescriptor) async throws {
        let outputURL = outputURL.appendingPathComponent(descriptor.name)
        
        var delta = descriptor.timecode
        delta.set(.realTime(seconds: gifSpan / 2), by: .clamping)
        
        let timeIn = descriptor.timecode - delta
        let timeOut = descriptor.timecode + delta
        let timeRange = timeIn ... timeOut
        
        let conversion = AnimatedImageExtractor.ConversionSettings(
            sourceMediaFile: videoPath,
            outputFolder: outputURL,
            timecodeRange: timeRange,
            dimensions: gifDimensions,
            outputFPS: gifFPS,
            imageFilter: {
                if let text = descriptor.label {
                    self.imageLabeler.labelImage(image: $0, text: text)
                } else { $0 }
            },
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
    let descriptors: [ImageDescriptor]
    let videoPath: URL
    let outputURL: URL
    let imageFormat: MarkerImageFormat.Still
    let imageJPGQuality: Double
    let imageDimensions: CGSize?
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger?
    let exportProfileProgress: Progress?
    let progressUnitCount: Int64
    
    private var imageLabeler: ImageLabeler
    
    init(
        descriptors: [ImageDescriptor],
        videoPath: URL,
        outputURL: URL,
        imageFormat: MarkerImageFormat.Still,
        imageJPGQuality: Double,
        imageDimensions: CGSize?,
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil,
        exportProfileProgress: Progress? = nil,
        progressUnitCount: Int64 = 0
    ) {
        self.descriptors = descriptors
        self.videoPath = videoPath
        self.outputURL = outputURL
        self.imageFormat = imageFormat
        self.imageJPGQuality = imageJPGQuality
        self.imageDimensions = imageDimensions
        self.imageLabelProperties = imageLabelProperties
        self.logger = logger ?? Logger(label: "\(Self.self)")
        self.exportProfileProgress = exportProfileProgress
        self.progressUnitCount = progressUnitCount
        
        imageLabeler = ImageLabeler(
            labelProperties: imageLabelProperties,
            logger: logger
        )
    }
    
    func write() throws {
        let conversion = ImageExtractor.ConversionSettings(
            sourceMediaFile: videoPath,
            outputFolder: outputURL,
            descriptors: descriptors,
            frameFormat: imageFormat,
            jpgQuality: imageJPGQuality,
            dimensions: imageDimensions,
            imageFilter: { image, label in
                if let label {
                    self.imageLabeler.labelImage(image: image, text: label)
                } else { image }
            }
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
