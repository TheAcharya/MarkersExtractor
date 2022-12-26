import AVFoundation
import Foundation
import CoreImage
import Logging
import OrderedCollections

final class ImageExtractor {
    enum Error: LocalizedError {
        case invalidSettings
        case unreadableFile
        case unsupportedType
        case labelsDepleted
        case generateFrameFailed(Swift.Error)
        case addFrameFailed(Swift.Error)
        case writeFailed(Swift.Error)

        var errorDescription: String? {
            switch self {
            case .invalidSettings:
                return "Invalid settings."
            case .unreadableFile:
                return "The selected file is no longer readable."
            case .unsupportedType:
                return "Image type is not supported"
            case .labelsDepleted:
                return "Image labels depleted before images"
            case .generateFrameFailed(let error):
                return "Failed to generate frame: \(error.localizedDescription)"
            case .addFrameFailed(let error):
                return "Failed to add frame, with underlying error: \(error.localizedDescription)"
            case .writeFailed(let error):
                return "Failed to write, with underlying error: \(error.localizedDescription)"
            }
        }
    }

    struct Conversion {
        let asset: AVAsset
        let sourceURL: URL
        let destURL: URL
        let timeCodes: OrderedDictionary<String, CMTime>
        let frameFormat: MarkerImageFormat
        let frameJPGQuality: Double?
        let dimensions: CGSize?
        let imageFilter: ((CGImage) -> CGImage)?
    }

    private let logger = Logger(label: "\(ImageExtractor.self)")

    private let conversion: Conversion

    init(_ conversion: Conversion) {
        self.conversion = conversion
    }

    static func convert(_ conversion: Conversion) throws {
        let conv = self.init(conversion)
        try conv.generateImages()
    }

    private func generateImages() throws {
        let generator = try imageGenerator()
        let times = Array(conversion.timeCodes.values)
        var frameNamesIterator = conversion.timeCodes.keys.makeIterator()

        var result: Result<Void, Error> = .failure(.invalidSettings)

        let group = DispatchGroup()
        group.enter()

        generator.generateCGImagesAsynchronously(forTimePoints: times) { [weak self] imageResult in
            guard let self = self else {
                result = .failure(.invalidSettings)
                group.leave()
                return
            }

            guard let frameName = frameNamesIterator.next() else {
                result = .failure(.labelsDepleted)
                group.leave()
                return
            }

            let frameResult = self.processFrame(for: imageResult, frameName: frameName)

            switch frameResult {
            case .success(let finished):
                if finished {
                    result = .success(())
                    group.leave()
                }
            case .failure(let error):
                result = .failure(error)
                group.leave()
            }
        }

        group.wait()

        switch result {
        case .failure(let error):
            throw error
        case .success:
            return
        }
    }

    private func imageGenerator() throws -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: conversion.asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        // This improves the performance a little bit.
        if let dimensions = conversion.dimensions {
            generator.maximumSize = CGSize(widthHeight: dimensions.longestSide)
        }

        return generator
    }

    private func processFrame(
        for result: Result<AVAssetImageGenerator.CompletionHandlerResult, Swift.Error>,
        frameName: String
    ) -> Result<Bool, Error> {
        switch result {
        case .success(let result):
            let image = conversion.imageFilter?(result.image) ?? result.image

            let cicontext = CIContext()
            let ciimage = CIImage(cgImage: image)

            let url = conversion.destURL.appendingPathComponent(frameName)

            var options = [:] as [CIImageRepresentationOption: Any]

            if let jpgQuality = conversion.frameJPGQuality {
                options = [
                    kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption:
                        jpgQuality
                ]
            }

            do {
                switch conversion.frameFormat {
                case .png:
                    try cicontext.writePNGRepresentation(
                        of: ciimage,
                        to: url,
                        format: .RGBA8,
                        colorSpace: ciimage.colorSpace!
                    )
                case .jpg:
                    try cicontext.writeJPEGRepresentation(
                        of: ciimage,
                        to: url,
                        colorSpace: ciimage.colorSpace!,
                        options: options
                    )
                default:
                    return .failure(.unsupportedType)
                }
            } catch {
                return .failure(.addFrameFailed(error))
            }

            return .success(result.isFinished)
        case .failure(let error):
            return .failure(.generateFrameFailed(error))
        }
    }
}
