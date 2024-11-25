//
//  StillImageBatchExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import CoreImage
import Foundation
import Logging
import OrderedCollections
import TimecodeKitCore

/// Extract one or more images from a video asset.
final class StillImageBatchExtractor {
    // MARK: - Properties
    
    private let logger: Logger
    private let conversion: ConversionSettings
    
    // ProgressReporting
    let progress: Progress
    
    // MARK: - Init
    
    init(_ conversion: ConversionSettings, logger: Logger? = nil) {
        self.logger = logger ?? Logger(label: "\(Self.self)")
        self.conversion = conversion
        progress = Progress()
    }
}

extension StillImageBatchExtractor: Sendable { }

// MARK: - Convert

extension StillImageBatchExtractor {
    /// - Throws: ``StillImageBatchExtractorError`` in the event of an unrecoverable error.
    /// - Returns: ``StillImageBatchExtractorResult`` if the batch operation completed either fully
    /// or partially.
    func convert() async throws -> StillImageBatchExtractorResult {
        progress.completedUnitCount = 0
        progress.totalUnitCount = Int64(conversion.descriptors.count)
        
        let generator = imageGenerator()
        
        let batchResult = StillImageBatchExtractorResult()
        
        try await generator.images(forTimesIn: conversion.descriptors, updating: progress)
            { [weak self, batchResult] descriptor, image, result in
                guard let self else {
                    await batchResult.addError(
                        for: descriptor,
                        .internalInconsistency("No reference to image extractor.")
                    )
                    return
                }

                let fileName = descriptor.filename
                let label = descriptor.label
            
                let frameResult = await self.processAndWriteFrameToDisk(
                    image: image,
                    result: result,
                    fileName: fileName,
                    label: label
                )
            
                switch frameResult {
                case let .success(isFinished):
                    if isFinished {
                        await batchResult.setFinished()
                    }
                case let .failure(error):
                    await batchResult.addError(for: descriptor, error)
                }
            }
        
        // TODO: throw error if `isBatchFinished == false`?
        // let isFinished = await batchResult.isBatchFinished
        // assert(isFinished)
        
        // sometimes NSProgress doesn't fully reach 1.0 so this assert is not reliable
        // assert(progress.fractionCompleted == 1.0)
        
        return batchResult
    }

    private func imageGenerator() -> AVAssetImageGeneratorWrapper {
        let asset = AVAsset(url: conversion.sourceMediaFile)
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        // This improves the performance a little bit.
        if let dimensions = conversion.dimensions {
            generator.maximumSize = CGSize(square: dimensions.longestSide)
        }

        return AVAssetImageGeneratorWrapper(generator)
    }

    private func processAndWriteFrameToDisk(
        image: CGImage,
        result: Result<AVAssetImageGeneratorWrapper.CompletionHandlerResult, Swift.Error>,
        fileName: String,
        label: String?
    ) async -> Result<Bool, StillImageBatchExtractorError> {
        switch result {
        case let .success(result):
            let image = await conversion.imageFilter?(image, label) ?? image
            
            let ciContext = CIContext()
            let ciImage = CIImage(cgImage: image)
            
            let fileURL = conversion.outputFolder.appendingPathComponent(fileName)
            
            do {
                switch conversion.frameFormat {
                case .png:
                    // PNG does not offer 'compression' or 'quality' options
                    try ciContext.writePNGRepresentation(
                        of: ciImage,
                        to: fileURL,
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
                        to: fileURL,
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
    struct ConversionSettings: Sendable {
        let descriptors: [ImageDescriptor]
        let sourceMediaFile: URL
        let outputFolder: URL
        let frameFormat: MarkerImageFormat.Still
        
        /// JPG quality: percentage as a unit interval between `0.0 ... 1.0`
        let jpgQuality: Double?
        
        let dimensions: CGSize?
        let imageFilter: (@Sendable (_ image: CGImage, _ label: String?) async -> CGImage)?
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

public actor StillImageBatchExtractorResult: Sendable {
    public var errors: [(descriptor: ImageDescriptor, error: StillImageBatchExtractorError)] = []
    public var isBatchFinished = false
    
    init(errors: [(descriptor: ImageDescriptor, error: StillImageBatchExtractorError)] = []) {
        self.errors = errors
    }
    
    func addError(
        for descriptor: ImageDescriptor,
        _ error: StillImageBatchExtractorError
    ) {
        errors.append((descriptor: descriptor, error: error))
    }
    
    func setFinished() {
        isBatchFinished = true
    }
}
