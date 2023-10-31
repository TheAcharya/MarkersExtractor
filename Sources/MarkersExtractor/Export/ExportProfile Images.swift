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
    let name: String
    let label: String?
}

protocol ImageWriterProtocol: ProgressReporting {
    func write() async throws
}

/// Generate animated images on disk.
/// For the time being, the only format supported is Animated GIF.
class AnimatedImagesWriter: NSObject, ImageWriterProtocol {
    let descriptors: [ImageDescriptor]
    let videoPath: URL
    let outputURL: URL
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
        videoPath: URL,
        outputURL: URL,
        gifFPS: Double,
        gifSpan: TimeInterval,
        gifDimensions: CGSize?,
        imageFormat: MarkerImageFormat.Animated,
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil
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
    }
    
    /// Write all images concurrently (in parallel) by multithreading.
    func write() async throws {
        progress.completedUnitCount = 0
        progress.totalUnitCount = Int64(descriptors.count)
        
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for descriptor in descriptors {
                taskGroup.addTask { [self] in
                    try await process(descriptor: descriptor)
                    progress.completedUnitCount += 1
                }
            }
        }
    }
    
    private func process(descriptor: ImageDescriptor) async throws {
        let outputFileWithoutExtension = outputURL.appendingPathComponent(descriptor.name)
        
        var delta = descriptor.timecode
        delta.set(.realTime(seconds: gifSpan / 2), by: .clamping)
        
        let timeIn = descriptor.timecode - delta
        let timeOut = descriptor.timecode + delta
        let timeRange = timeIn ... timeOut
        
        let conversion = AnimatedImageExtractor.ConversionSettings(
            sourceMediaFile: videoPath,
            outputFileWithoutExtension: outputFileWithoutExtension,
            timecodeRange: timeRange,
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
                let markerName = descriptor.name.quoted
                let err = error.error.localizedDescription
                logger.warning("Error while generating image for marker at \(tc) \(markerName): \(err)")
            }
        } catch let err as AnimatedImageExtractorError {
            throw MarkersExtractorError.extraction(.image(.animatedImage(err)))
        } catch {
            throw MarkersExtractorError.extraction(.image(.generic(
                "Error while generating animated thumbnail \(outputURL.lastPathComponent.quoted):"
                + " \(error.localizedDescription)"
            )))
        }
    }
}

/// Generate still images on disk.
class ImagesWriter: NSObject, ImageWriterProtocol {
    let descriptors: [ImageDescriptor]
    let videoPath: URL
    let outputURL: URL
    let imageFormat: MarkerImageFormat.Still
    let imageJPGQuality: Double
    let imageDimensions: CGSize?
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger
    
    let extractor: StillImageBatchExtractor
    
    // ProgressReporting
    let progress: Progress
    
    init(
        descriptors: [ImageDescriptor],
        videoPath: URL,
        outputURL: URL,
        imageFormat: MarkerImageFormat.Still,
        imageJPGQuality: Double,
        imageDimensions: CGSize?,
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil
    ) {
        self.descriptors = descriptors
        self.videoPath = videoPath
        self.outputURL = outputURL
        self.imageFormat = imageFormat
        self.imageJPGQuality = imageJPGQuality
        self.imageDimensions = imageDimensions
        self.imageLabelProperties = imageLabelProperties
        self.logger = logger ?? Logger(label: "\(Self.self)")
        
        let conversion = StillImageBatchExtractor.ConversionSettings(
            sourceMediaFile: videoPath,
            outputFolder: outputURL,
            descriptors: descriptors,
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
                let markerName = error.descriptor.name.quoted
                let err = error.error.localizedDescription
                logger.warning("Error while generating image for marker at \(tc) \(markerName): \(err)")
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
