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

public struct ImageDescriptor: Sendable {
    let timecode: Timecode
    let filename: String
    let label: String?
}

protocol ImageWriterProtocol: ProgressReporting {
    func write() async throws
}

/// Generate animated images on disk.
class AnimatedImagesWriter: NSObject, ImageWriterProtocol {
    let descriptors: [ImageDescriptor]
    let sourceMediaFile: URL
    let outputFolder: URL
    let gifFPS: Double
    let gifSpan: TimeInterval
    let gifDimensions: CGSize?
    let imageFormat: MarkerImageFormat.Animated
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger
    
    // ProgressReporting
    let progress: Progress = Progress()
    
    init(
        descriptors: [ImageDescriptor],
        sourceMediaFile: URL,
        outputFolder: URL,
        gifFPS: Double,
        gifSpan: TimeInterval,
        gifDimensions: CGSize?,
        imageFormat: MarkerImageFormat.Animated,
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil
    ) {
        self.descriptors = descriptors
        self.sourceMediaFile = sourceMediaFile
        self.outputFolder = outputFolder
        self.gifFPS = gifFPS
        self.gifSpan = gifSpan
        self.gifDimensions = gifDimensions
        self.imageFormat = imageFormat
        self.imageLabelProperties = imageLabelProperties
        self.logger = logger ?? Logger(label: "\(Self.self)")
    }
    
    /// Write all images concurrently (in parallel) by multithreading.
    func write() async throws {
        progress.completedUnitCount = 0
        progress.totalUnitCount = Int64(descriptors.count)
        
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for descriptor in descriptors {
                taskGroup.addTask { [self] in
                    try await write(descriptor: descriptor)
                    progress.completedUnitCount += 1
                }
            }
        }
        
        assert(progress.fractionCompleted == 1.0)
    }
    
    private func write(descriptor: ImageDescriptor) async throws {
        let outputFile = outputFolder.appendingPathComponent(descriptor.filename)
        
        var delta = descriptor.timecode
        delta.set(.realTime(seconds: gifSpan / 2), by: .clamping)
        
        let timeIn = try descriptor.timecode.subtracting(delta, by: .clamping)
        let timeOut = try descriptor.timecode.adding(delta, by: .clamping)
        let timeRange = timeIn ... timeOut
        
        let conversion = AnimatedImageExtractor.ConversionSettings(
            timecodeRange: timeRange,
            sourceMediaFile: sourceMediaFile,
            outputFile: outputFile,
            dimensions: gifDimensions,
            outputFPS: gifFPS,
            imageFilter: { [weak self] inputImage in
                if let self, let label = descriptor.label {
                    var labeler = ImageLabeler(labelProperties: self.imageLabelProperties, logger: self.logger)
                    return await labeler.labelImage(image: inputImage, text: label)
                } else {
                    return inputImage
                }
            },
            imageFormat: imageFormat
        )
        
        do {
            let extractor = try AnimatedImageExtractor(conversion, logger: logger)
            let result = try await extractor.convert()
            
            // post errors to console if operation partially completed
            for error in result.errors {
                let tc = descriptor.timecode.stringValue()
                let filename = descriptor.filename.quoted
                let err = error.error.localizedDescription
                logger.warning("Error while generating image \(filename) for marker at \(tc): \(err)")
            }
        } catch let err as AnimatedImageExtractorError {
            throw MarkersExtractorError.extraction(.image(.animatedImage(err)))
        } catch {
            let filename = descriptor.filename.quoted
            let err = error.localizedDescription
            throw MarkersExtractorError.extraction(.image(.generic(
                "Error while generating animated thumbnail \(filename): \(err)"
            )))
        }
    }
}

/// Generate still images on disk.
class ImagesWriter: NSObject, ImageWriterProtocol {
    let descriptors: [ImageDescriptor]
    let sourceMediaFile: URL
    let outputFolder: URL
    let imageFormat: MarkerImageFormat.Still
    /// Quality for compressed image formats (0.0 ... 1.0)
    let imageJPGQuality: Double
    let imageDimensions: CGSize?
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger
    
    let extractor: StillImageBatchExtractor
    
    // ProgressReporting
    let progress: Progress
    
    init(
        descriptors: [ImageDescriptor],
        sourceMediaFile: URL,
        outputFolder: URL,
        imageFormat: MarkerImageFormat.Still,
        imageJPGQuality: Double,
        imageDimensions: CGSize?,
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil
    ) {
        self.descriptors = descriptors
        self.sourceMediaFile = sourceMediaFile
        self.outputFolder = outputFolder
        self.imageFormat = imageFormat
        self.imageJPGQuality = imageJPGQuality
        self.imageDimensions = imageDimensions
        self.imageLabelProperties = imageLabelProperties
        self.logger = logger ?? Logger(label: "\(Self.self)")
        
        let conversion = StillImageBatchExtractor.ConversionSettings(
            descriptors: descriptors,
            sourceMediaFile: sourceMediaFile,
            outputFolder: outputFolder,
            frameFormat: imageFormat,
            jpgQuality: imageJPGQuality,
            dimensions: imageDimensions,
            imageFilter: { inputImage, label in
                if let label {
                    var labeler = ImageLabeler(labelProperties: imageLabelProperties, logger: logger)
                    return await labeler.labelImage(image: inputImage, text: label)
                } else {
                    return inputImage
                }
            }
        )
        
        extractor = StillImageBatchExtractor(conversion, logger: logger)
        progress = extractor.progress
    }
    
    func write() async throws {
        do {
            let result = try await extractor.convert()
            // post errors to console if operation partially completed
            for error in result.errors {
                let tc = error.descriptor.timecode.stringValue()
                let filename = error.descriptor.filename.quoted
                let err = error.error.localizedDescription
                logger.warning("Error while generating image \(filename) for marker at \(tc): \(err)")
            }
        } catch let err as StillImageBatchExtractorError {
            throw MarkersExtractorError.extraction(.image(.stillImage(err)))
        } catch {
            throw MarkersExtractorError.extraction(.image(.generic(
                "Error while generating images: \(error.localizedDescription)"
            )))
        }
    }
}
