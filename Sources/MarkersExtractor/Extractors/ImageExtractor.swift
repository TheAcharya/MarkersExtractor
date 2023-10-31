//
//  ImageExtractor.swift
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
final class ImageExtractor: NSObject, ProgressReporting {
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

extension ImageExtractor {
    /// - Throws: ``ImageExtractorError``
    func convert() throws {
        let generator = imageGenerator()
        
        // TODO: these iterators need to go. it's super brittle. refactor to process all variables together in a single descriptor.
        let times = conversion.descriptors.map(\.timecode).map(\.cmTimeValue)
        var frameNamesIterator = conversion.descriptors.map(\.name).makeIterator()
        var labelsIterator = conversion.descriptors.map(\.label).makeIterator()
        
        var result: Result<Void, ImageExtractorError> = .failure(.internalInconsistency)

        let group = DispatchGroup()
        group.enter()

        generator.generateCGImagesAsynchronously(
            forTimePoints: times,
            updating: progress
        ) { [weak self] imageResult in
            guard let self = self else {
                result = .failure(.internalInconsistency)
                group.leave()
                return
            }

            guard let frameName = frameNamesIterator.next() else {
                result = .failure(.labelsDepleted)
                group.leave()
                return
            }
            
            guard let label = labelsIterator.next() else {
                result = .failure(.labelsDepleted)
                group.leave()
                return
            }

            let frameResult = self.processAndWriteFrameToDisk(
                for: imageResult,
                frameName: frameName,
                label: label
            )

            // TODO: Throw on first error, don't just update with the last error and then check at the end of the batch
            switch frameResult {
            case let .success(finished):
                if finished {
                    result = .success(())
                    group.leave()
                }
            case let .failure(error):
                result = .failure(error)
                group.leave()
            }
        }

        group.wait()

        switch result {
        case let .failure(error):
            throw error
        case .success:
            return
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
    ) -> Result<Bool, ImageExtractorError> {
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

extension ImageExtractor {
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

/// Static image extraction error.
public enum ImageExtractorError: LocalizedError {
    case internalInconsistency
    case unreadableFile
    case unsupportedType
    case labelsDepleted
    case generateFrameFailed(Swift.Error)
    case addFrameFailed(Swift.Error)
    case writeFailed(Swift.Error)
    
    public var errorDescription: String? {
        switch self {
        case .internalInconsistency:
            return "Internal error occurred."
        case .unreadableFile:
            return "The selected file is no longer readable."
        case .unsupportedType:
            return "Image type is not supported."
        case .labelsDepleted:
            return "Image labels depleted before images."
        case let .generateFrameFailed(error):
            return "Failed to generate frame: \(error.localizedDescription)"
        case let .addFrameFailed(error):
            return "Failed to add frame, with underlying error: \(error.localizedDescription)"
        case let .writeFailed(error):
            return "Failed to write, with underlying error: \(error.localizedDescription)"
        }
    }
}
