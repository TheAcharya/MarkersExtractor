//
//  AnimatedImagesWriter.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKitCore

/// Generate animated images on disk.
final actor AnimatedImagesWriter: ImageWriterProtocol {
    let descriptors: [ImageDescriptor]
    let sourceMediaFile: URL
    let outputFolder: URL
    let gifFPS: Double
    let gifSpan: TimeInterval
    let gifDimensions: CGSize?
    let imageFormat: MarkerImageFormat.Animated
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger
    
    // ProgressReporting (omitted protocol conformance as it would force NSObject inheritance)
    let progress = Progress()
    
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
}

// MARK: - Methods

extension AnimatedImagesWriter {
    /// Write all images concurrently (in parallel) by multithreading.
    func write() async throws {
        progress.completedUnitCount = 0
        progress.totalUnitCount = Int64(descriptors.count)
        
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for descriptor in descriptors {
                taskGroup.addTask { [self] in
                    try await write(descriptor: descriptor)
                    progress.completedUnitCount += 1
                }
            }
            
            try await taskGroup.waitForAll()
        }
        
        // TODO: NSProgress is wonky, sometimes its not fully 1.0 so asserting here isn't helpful
        // assert(progress.fractionCompleted == 1.0)
    }
}

// MARK: - Private Methods

extension AnimatedImagesWriter {
    private func write(descriptor: ImageDescriptor) async throws {
        let outputFile = outputFolder.appendingPathComponent(descriptor.filename)
        
        var delta = descriptor.offsetFromVideoStart
        delta.set(.realTime(seconds: gifSpan / 2), by: .clamping)
        
        let timeIn = try descriptor.offsetFromVideoStart.subtracting(delta, by: .clamping)
        let timeOut = try descriptor.offsetFromVideoStart.adding(delta, by: .clamping)
        let timeRange = timeIn ... timeOut
        
        let conversion = AnimatedImageExtractor.ConversionSettings(
            timecodeRange: timeRange,
            sourceMediaFile: sourceMediaFile,
            outputFile: outputFile,
            dimensions: gifDimensions,
            outputFPS: gifFPS,
            imageFilter: { [weak self] inputImage in
                if let self, let label = descriptor.label {
                    var labeler = ImageLabeler(
                        labelProperties: self.imageLabelProperties,
                        logger: self.logger
                    )
                    return labeler.labelImage(image: inputImage, text: label)
                } else {
                    return inputImage
                }
            },
            imageFormat: imageFormat
        )
        
        do {
            let extractor = try await AnimatedImageExtractor(conversion, logger: logger)
            let result = try await extractor.convert()
            
            // post errors to console if operation partially completed
            for error in await result.errors {
                let tc = descriptor.absoluteTimecode.stringValue()
                let filename = descriptor.filename.quoted
                let err = error.error.localizedDescription
                logger.warning(
                    "Error while generating image \(filename) for marker at \(tc): \(err)"
                )
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
