//
//  AVAssetImageGenerator.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
import AVFoundation

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
        completionHandler: @escaping (_ descriptor: ImageDescriptor,
                                      _ imageResult: Swift.Result<CompletionHandlerResult, Error>) async -> Void
    ) async throws {
        let totalCount = Counter(count: descriptors.count) { count in
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        let completedCount = Counter(count: 0) { count in
            progress?.completedUnitCount = Int64(exactly: count) ?? 0
        }
        
        await withThrowingTaskGroup(of: Void.self) { [weak self] taskGroup in
            for descriptor in descriptors {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    
                    let requestedTime = descriptor.timecode.cmTimeValue
                    
                    let result = try await imageCompat(at: requestedTime)
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
                }
            }
        }
    }
    
    func images(
        forTimes times: [CMTime],
        updating progress: Progress? = nil,
        completionHandler: @escaping (_ time: CMTime,
                                      _ imageResult: Swift.Result<CompletionHandlerResult, Error>) -> Void
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
                    
                    let result = try await imageCompat(at: requestedTime)
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
        
        var resultImage: CGImage? = nil
        var resultError: Error? = nil
        var resultActualTime: CMTime? = nil
        var isNoFrame: Bool = false
        
        let group = DispatchGroup()
        group.enter()
        
        let nsValue = NSValue(time: time)
        generateCGImagesAsynchronously(forTimes: [nsValue])
        { /*requestedTime*/ _, image, actualTime, result, error in
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
                        isNoFrame = true
                    case .decodeFailed:
                        // macOS 11 (still an issue in macOS 11.2) started throwing “decode failed”
                        // error for some frames in screen recordings.
                        // As a workaround, we ignore these as the GIF seems fine still.
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
                resultError = MarkersExtractorError.extraction(.image(.generic("Unhandled image result case.")))
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
                    continuation.resume(throwing: MarkersExtractorError.extraction(.image(.generic("Unknown error."))))
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
