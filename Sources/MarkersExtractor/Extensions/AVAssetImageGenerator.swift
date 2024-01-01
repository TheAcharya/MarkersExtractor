//
//  AVAssetImageGenerator.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
import AVFoundation
import TimecodeKit

extension AVAssetImageGenerator {
    struct CompletionHandlerResult {
        let image: CGImage
        let requestedTime: CMTime
        let actualTime: CMTime
        let completedCount: Int
        let totalCount: Int
        let isFinished: Bool
        let isFinishedIgnoreImage: Bool
    }
    
    func images(
        forTimesIn descriptors: [ImageDescriptor],
        updating progress: Progress? = nil,
        completionHandler: @escaping (
            _ descriptor: ImageDescriptor,
            _ imageResult: Swift
                .Result<CompletionHandlerResult, Error>
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
        ) { [weak self] taskGroup in
            for descriptor in descriptors {
                taskGroup.addTask { [weak self] in
                    guard let self else { return nil }
                    
                    let requestedTime = descriptor.offsetFromVideoStart.cmTimeValue
                    
                    let result = try await self.imageCompat(at: requestedTime)
                    let hasImage = result.image != nil
                    let imageForHandlerResult = result.image ?? CGImage.empty!
                    
                    if hasImage {
                        completedCount.increment()
                    } else {
                        totalCount.decrement()
                    }
                    
                    let isFinished = completedCount.count == totalCount.count
                    
                    await completionHandler(
                        descriptor,
                        .success(
                            CompletionHandlerResult(
                                image: imageForHandlerResult,
                                requestedTime: requestedTime,
                                actualTime: result.actualTime,
                                completedCount: completedCount.count,
                                totalCount: totalCount.count,
                                isFinished: isFinished,
                                isFinishedIgnoreImage: isFinished && !hasImage
                            )
                        )
                    )
                    
                    // we have to use Fraction as dictionary key since CMTime is not hashable on
                    // older macOS versions
                    
                    if hasImage {
                        return (
                            fraction: descriptor.absoluteTimecode.cmTimeValue.fractionValue,
                            image: imageForHandlerResult
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
    
    func images(
        forTimes times: [CMTime],
        updating progress: Progress? = nil,
        completionHandler: @escaping (
            _ time: CMTime,
            _ imageResult: Swift.Result<CompletionHandlerResult, Error>
        )
            -> Void
    ) async throws {
        let totalCount = Counter(count: times.count) { count in
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        let completedCount = Counter(count: 0) { count in
            progress?.completedUnitCount = Int64(exactly: count) ?? 0
        }
        
        await withThrowingTaskGroup(of: Void.self) { [weak self] taskGroup in
            for requestedTime in times {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    
                    let result = try await self.imageCompat(at: requestedTime)
                    let hasImage = result.image != nil
                    let imageForHandlerResult = result.image ?? CGImage.empty!
                    
                    if hasImage {
                        completedCount.increment()
                    } else {
                        totalCount.decrement()
                    }
                    
                    let isFinished = completedCount.count == totalCount.count
                    
                    completionHandler(
                        requestedTime,
                        .success(
                            CompletionHandlerResult(
                                image: imageForHandlerResult,
                                requestedTime: requestedTime,
                                actualTime: result.actualTime,
                                completedCount: completedCount.count,
                                totalCount: totalCount.count,
                                isFinished: isFinished,
                                isFinishedIgnoreImage: isFinished && !hasImage
                            )
                        )
                    )
                }
            }
        }
    }
                                  
    /// Backward-compatible implementation of Apple's `image(at time: CMTime)`.
    func imageCompat(at time: CMTime) async throws -> (image: CGImage?, actualTime: CMTime) {
        if #available(macOS 13.0, *) {
            return try await image(at: time)
        }
        
        var resultImage: CGImage?
        var resultError: Error?
        var resultActualTime: CMTime?
        var isNoFrame = false
        
        let group = DispatchGroup()
        group.enter()
        
        let nsValue = NSValue(time: time)
        generateCGImagesAsynchronously(forTimes: [nsValue])
            { requestedTime, image, actualTime, result, error in
                defer { group.leave() }
            
                resultImage = image
                resultError = error
                resultActualTime = actualTime
            
                switch result {
                case .succeeded:
                    break
                
                case .failed:
                    guard let error else {
                        resultError = MarkersExtractorError.extraction(.image(.generic(
                            "Image generator failed but no additional error information is available."
                        )))
                        return
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
                    resultError = CancellationError()
                
                @unknown default:
                    resultError = MarkersExtractorError
                        .extraction(.image(.generic("Unhandled image result case.")))
                }
            }
        
        return try await withCheckedThrowingContinuation { continuation in
            group.notify(queue: .main) {
                if isNoFrame, let resultActualTime {
                    let tuple = (image: CGImage?.none, actualTime: resultActualTime)
                    continuation.resume(with: .success(tuple))
                } else if let resultError {
                    continuation.resume(throwing: resultError)
                } else if let resultImage, let resultActualTime {
                    let tuple = (image: resultImage, actualTime: resultActualTime)
                    continuation.resume(with: .success(tuple))
                } else {
                    continuation
                        .resume(
                            throwing: MarkersExtractorError
                                .extraction(.image(.generic("Unknown error.")))
                        )
                }
            }
        }
    }
}

extension AVAssetImageGenerator {
    func image(at time: CMTime) -> NSImage? {
        (try? copyCGImage(at: time, actualTime: nil))?
            .nsImage
    }
}
