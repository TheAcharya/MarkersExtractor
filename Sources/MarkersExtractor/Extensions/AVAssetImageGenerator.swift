//
//  AVAssetImageGenerator.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
@preconcurrency import AVFoundation
import SwiftTimecodeCore

actor AVAssetImageGeneratorWrapper {
    private let imageGenerator: AVAssetImageGenerator
    
    init(asset: AVAsset) {
        imageGenerator = AVAssetImageGenerator(asset: asset)
    }
    
    init(_ imageGenerator: AVAssetImageGenerator) {
        self.imageGenerator = imageGenerator
    }
}

extension AVAssetImageGeneratorWrapper {
    struct CompletionHandlerResult: Sendable {
        let requestedTime: CMTime
        let actualTime: CMTime
        let completedCount: Int
        let totalCount: Int
        let isFinished: Bool
        let isFinishedIgnoreImage: Bool
    }
    
    @discardableResult
    func images(
        forTimesIn descriptors: [ImageDescriptor],
        updating progress: Progress? = nil,
        completionHandler: sending @escaping @Sendable (
            _ descriptor: ImageDescriptor,
            _ image: inout CGImage,
            _ result: Swift.Result<CompletionHandlerResult, Error>
        ) async -> Void
    ) async throws -> [Fraction: CGImage] {
        let totalCount = Counter(count: descriptors.count) { count in
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        let completedCount = Counter(count: 0) { count in
            progress?.completedUnitCount = Int64(exactly: count) ?? 0
        }
        
        let images: [Fraction: CGImage] = try await withThrowingTaskGroup(
            of: (fraction: Fraction, image: CGImage)?.self
        ) { [weak self, totalCount, completedCount, completionHandler] taskGroup in
            for descriptor in descriptors {
                taskGroup.addTask { [weak self, totalCount, completedCount, completionHandler] in
                    guard let self else { return nil }
                    
                    let requestedTime = descriptor.offsetFromVideoStart.cmTimeValue
                    
                    let result = try await self.imageCompat(at: requestedTime)
                    let hasImage = result.image != nil
                    var image = result.image ?? CGImage.empty!
                    
                    if hasImage {
                        await completedCount.increment()
                    } else {
                        await totalCount.decrement()
                    }
                    
                    let isFinished = await completedCount.count == totalCount.count
                    
                    let completionResult = await CompletionHandlerResult(
                        requestedTime: requestedTime,
                        actualTime: result.actualTime,
                        completedCount: completedCount.count,
                        totalCount: totalCount.count,
                        isFinished: isFinished,
                        isFinishedIgnoreImage: isFinished && !hasImage
                    )
                    await completionHandler(
                        descriptor,
                        &image,
                        .success(completionResult)
                    )
                    
                    if hasImage {
                        // we have to use Fraction as dictionary key since CMTime is not hashable on
                        // older macOS versions
                        return (
                            fraction: descriptor.absoluteTimecode.cmTimeValue.fractionValue,
                            image: image
                        )
                    } else {
                        return nil
                    }
                }
            }
            
            var images: [Fraction: CGImage] = [:]
            for try await result in taskGroup {
                guard let result else { continue }
                images[result.fraction] = result.image
            }
            
            return images
        }
        
        return images
    }
    
    @discardableResult
    func images(
        forTimes times: [CMTime],
        updating progress: Progress? = nil,
        completionHandler: sending @escaping @Sendable (
            _ time: CMTime,
            _ image: inout CGImage,
            _ imageResult: Swift.Result<CompletionHandlerResult, Error>
        ) async -> Void
    ) async throws -> [Fraction: CGImage] {
        let totalCount = Counter(count: times.count) { count in
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        let completedCount = Counter(count: 0) { count in
            progress?.completedUnitCount = Int64(exactly: count) ?? 0
        }
        
        let images: [Fraction: CGImage] = try await withThrowingTaskGroup(
            of: (fraction: Fraction, image: CGImage)?.self
        ) { [weak self, totalCount, completedCount, completionHandler] taskGroup in
            for requestedTime in times {
                taskGroup.addTask { [weak self, totalCount, completedCount, completionHandler] in
                    guard let self else { return nil }
                    
                    let result = try await self.imageCompat(at: requestedTime)
                    let hasImage = result.image != nil
                    var image = result.image ?? CGImage.empty!
                    
                    if hasImage {
                        await completedCount.increment()
                    } else {
                        await totalCount.decrement()
                    }
                    
                    let isFinished = await completedCount.count == totalCount.count
                    
                    let completionResult = await CompletionHandlerResult(
                        requestedTime: requestedTime,
                        actualTime: result.actualTime,
                        completedCount: completedCount.count,
                        totalCount: totalCount.count,
                        isFinished: isFinished,
                        isFinishedIgnoreImage: isFinished && !hasImage
                    )
                    await completionHandler(
                        requestedTime,
                        &image,
                        .success(completionResult)
                    )
                    
                    if hasImage {
                        // we have to use Fraction as dictionary key since CMTime is not hashable on
                        // older macOS versions
                        return (
                            fraction: requestedTime.fractionValue,
                            image: image
                        )
                    } else {
                        return nil
                    }
                }
            }
            
            var images: [Fraction: CGImage] = [:]
            for try await result in taskGroup {
                guard let result else { continue }
                images[result.fraction] = result.image
            }
            
            return images
        }
        
        return images
    }
                                  
    /// Backward-compatible implementation of Apple's `image(at time: CMTime)`.
    func imageCompat(at time: CMTime) async throws -> (image: CGImage?, actualTime: CMTime) {
        // if #available(macOS 13.0, *) {
        //     return try await image(at: time)
        // }
        
        var isNoFrame = false
        
        let (requestedTime, image, actualTime, result, error) = await imageGenerator.generateCGImages(forTimes: [time])
        
        switch result {
        case .succeeded:
            break
            
        case .failed:
            guard let error else {
                throw MarkersExtractorError.extraction(.image(.generic(
                    "Image generator failed but no additional error information is available."
                )))
            }
            
            // Handle blank frames
            switch error {
            case let avError as AVError:
                switch avError.code {
                case .noImageAtTime:
                    // We ignore blank frames.
                    #if DEBUG
                    print(
                        "No image at requested time \(Fraction(requestedTime)), actual time \(Fraction(actualTime))"
                    )
                    #endif
                    isNoFrame = true
                case .decodeFailed:
                    // macOS 11 (still an issue in macOS 11.2) started throwing “decode
                    // failed”
                    // error for some frames in screen recordings.
                    // As a workaround, we ignore these as the GIF seems fine still.
                    #if DEBUG
                    print(
                        "Decode failed at requested time \(Fraction(requestedTime)), actual time \(Fraction(actualTime))"
                    )
                    #endif
                    isNoFrame = true
                default:
                    break
                }
                
            default:
                break
            }
        case .cancelled:
            throw CancellationError()
            
        @unknown default:
            throw MarkersExtractorError.extraction(.image(.generic(
                "Unhandled image result case."
            )))
        }
        
        if isNoFrame {
            return (image: nil, actualTime: actualTime)
        } else {
            return (image: image, actualTime: actualTime)
        }
    }
}

extension AVAssetImageGenerator {
    func image(at time: CMTime) -> NSImage? {
        (try? copyCGImage(at: time, actualTime: nil))?
            .nsImage
    }
}

extension AVAssetImageGenerator {
    // TODO: It's possible that in future Apple adds their own async method, at which time this wrapper can be removed.
    /// Swift Concurrency wrapper for `generateCGImagesAsynchronously` method.
    @_disfavoredOverload
    func generateCGImages(
        forTimes requestedTimes: [NSValue]
    ) async -> (
        requestedTime: CMTime,
        image: CGImage?,
        actualTime: CMTime,
        result: AVAssetImageGenerator.Result,
        error: (any Error)?)
    {
        await withCheckedContinuation { continuation in
            generateCGImagesAsynchronously(forTimes: requestedTimes) { requestedTime, image, actualTime, result, error in
                continuation.resume(returning: (requestedTime, image, actualTime, result, error))
            }
        }
    }
    
    // TODO: It's possible that in future Apple adds their own async method, at which time this wrapper can be removed.
    /// Swift Concurrency wrapper for `generateCGImagesAsynchronously` method.
    @_disfavoredOverload
    func generateCGImages(
        forTimes requestedTimes: [CMTime]
    ) async -> (
        requestedTime: CMTime,
        image: CGImage?,
        actualTime: CMTime,
        result: AVAssetImageGenerator.Result,
        error: (any Error)?)
    {
        let requestedTimes = requestedTimes.map(NSValue.init(time:))
        return await generateCGImages(forTimes: requestedTimes)
    }
}
