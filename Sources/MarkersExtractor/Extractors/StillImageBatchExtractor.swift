//
//  StillImageBatchExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import CoreImage
import Logging
import OrderedCollections
import TimecodeKit

/// Extract one or more images from a video asset.
final class StillImageBatchExtractor: NSObject, ProgressReporting {
    // MARK: - Properties
    
    private let logger: Logger
    private let conversion: ConversionSettings
    
    // ProgressReporting
    let progress: Progress
    
    // MARK: - Init
    
    init(_ conversion: ConversionSettings, logger: Logger? = nil) {
        self.logger = logger ?? Logger(label: "\(Self.self)")
        self.conversion = conversion
        progress = Progress(totalUnitCount: Int64(conversion.descriptors.count))
    }
}

// MARK: - Convert

extension StillImageBatchExtractor {
    /// - Throws: ``StillImageBatchExtractorError``
    func convert() async throws {
        let generator = imageGenerator()
        
        // TODO: these iterators need to go. it's super brittle. refactor to process all variables together in a single descriptor.
        let times = conversion.descriptors.map(\.timecode).map(\.cmTimeValue)
        var frameNamesIterator = conversion.descriptors.map(\.name).makeIterator()
        var labelsIterator = conversion.descriptors.map(\.label).makeIterator()
        
        var result: Result<Void, StillImageBatchExtractorError> = .failure(
            .internalInconsistency("Image generation could not start.")
        )

        let group = DispatchGroup()
        
        let proposedImageCount = times.count
        for _ in 0 ..< proposedImageCount { group.enter() }

        generator.generateCGImagesAsynchronously(
            forTimePoints: times,
            updating: progress
        ) { [weak self] imageResult in
            defer { group.leave() }
            
            guard let self = self else {
                result = .failure(.internalInconsistency("No reference to image extractor."))
                return
            }

            guard let frameName = frameNamesIterator.next() else {
                result = .failure(.internalInconsistency("Image extractor depleted names."))
                return
            }
            
            guard let label = labelsIterator.next() else {
                result = .failure(.internalInconsistency("Image extractor depleted labels."))
                return
            }

            let frameResult = self.processAndWriteFrameToDisk(
                for: imageResult,
                frameName: frameName,
                label: label
            )

            // TODO: Throw on first error, don't just update with the last error and then check at the end of the batch
            switch frameResult {
            case let .success(isFinished):
                if isFinished {
                    result = .success(())
                }
            case let .failure(error):
                result = .failure(error)
            }
        }
        
        try await withCheckedThrowingContinuation { continuation in
            group.notify(queue: .main) {
                continuation.resume(with: result)
            }
        }
    }

    private func imageGenerator() -> AVAssetImageGenerator {
        let asset = AVAsset(url: conversion.sourceMediaFile)
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        // This improves the performance a little bit.
        if let dimensions = conversion.dimensions {
            generator.maximumSize = CGSize(square: dimensions.longestSide)
        }

        return generator
    }

    private func processAndWriteFrameToDisk(
        for result: Result<AVAssetImageGenerator.CompletionHandlerResult, Swift.Error>,
        frameName: String,
        label: String?
    ) -> Result<Bool, StillImageBatchExtractorError> {
        switch result {
        case let .success(result):
            let image = conversion.imageFilter?(result.image, label) ?? result.image

            let ciContext = CIContext()
            let ciImage = CIImage(cgImage: image)

            let url = conversion.outputFolder.appendingPathComponent(frameName)

            do {
                switch conversion.frameFormat {
                case .png:
                    // PNG does not offer 'compression' or 'quality' options
                    try ciContext.writePNGRepresentation(
                        of: ciImage,
                        to: url,
                        format: .RGBA8,
                        colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
                    )
                case .jpg:
                    var options = [:] as [CIImageRepresentationOption: Any]
                    
                    if let jpgQuality = conversion.jpgQuality {
                        options = [
                            kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption:
                                jpgQuality
                        ]
                    }
                    
                    try ciContext.writeJPEGRepresentation(
                        of: ciImage,
                        to: url,
                        colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                        options: options
                    )
                }
            } catch {
                return .failure(.addFrameFailed(error))
            }

            return .success(result.isFinished)
        case let .failure(error):
            return .failure(.generateFrameFailed(error))
        }
    }
}

// MARK: - Types

extension StillImageBatchExtractor {
    struct ConversionSettings {
        let sourceMediaFile: URL
        let outputFolder: URL
        let descriptors: [ImageDescriptor]
        let frameFormat: MarkerImageFormat.Still
        
        /// JPG quality: percentage as a unit interval between `0.0 ... 1.0`
        let jpgQuality: Double?
        
        let dimensions: CGSize?
        let imageFilter: ((_ image: CGImage, _ label: String?) -> CGImage)?
    }
}

/// Still image extraction error.
public enum StillImageBatchExtractorError: LocalizedError {
    case internalInconsistency(_ verboseError: String)
    case unreadableFile
    case unsupportedType
    case generateFrameFailed(Swift.Error)
    case addFrameFailed(Swift.Error)
    case writeFailed(Swift.Error)
    
    public var errorDescription: String? {
        switch self {
        case let .internalInconsistency(verboseError):
            return "Internal error occurred: \(verboseError)"
        case .unreadableFile:
            return "The selected file is no longer readable."
        case .unsupportedType:
            return "Image type is not supported."
        case let .generateFrameFailed(error):
            return "Failed to generate frame: \(error.localizedDescription)"
        case let .addFrameFailed(error):
            return "Failed to add frame, with underlying error: \(error.localizedDescription)"
        case let .writeFailed(error):
            return "Failed to write, with underlying error: \(error.localizedDescription)"
        }
    }
}
