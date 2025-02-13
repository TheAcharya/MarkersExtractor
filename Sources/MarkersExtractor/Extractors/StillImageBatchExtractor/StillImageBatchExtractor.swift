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
    private let logger: Logger
    private let conversion: ConversionSettings
    
    // ProgressReporting (omitted protocol conformance as it would force NSObject inheritance)
    let progress: Progress
    
    // MARK: - Init
    
    init(_ conversion: ConversionSettings, logger: Logger? = nil) {
        self.logger = logger ?? Logger(label: "\(Self.self)")
        self.conversion = conversion
        progress = Progress()
    }
}

extension StillImageBatchExtractor: Sendable { }

// MARK: - Public Methods

extension StillImageBatchExtractor {
    /// - Throws: ``StillImageBatchExtractorError`` in the event of an unrecoverable error.
    /// - Returns: ``StillImageBatchExtractorResult`` if the batch operation completed either fully
    /// or partially.
    func convert() async throws -> BatchResult {
        progress.completedUnitCount = 0
        progress.totalUnitCount = Int64(conversion.descriptors.count)
        
        let generator = imageGenerator()
        
        let batchResult = BatchResult()
        
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
}

// MARK: - Private Methods

extension StillImageBatchExtractor {
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
