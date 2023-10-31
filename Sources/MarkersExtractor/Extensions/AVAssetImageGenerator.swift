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
    
    private class Counter {
        private(set) var count: Int
        private let onUpdate: ((_ count: Int) -> Void)?
        
        init(count: Int, onUpdate: ((_ count: Int) -> Void)? = nil) {
            self.count = count
            self.onUpdate = onUpdate
        }
        
        func increment() { setCount(count + 1) }
        func decrement() { setCount(count - 1) }
        func setCount(_ count: Int) {
            self.count = count
            onUpdate?(count)
        }
    }
    
    func images(
        forTimesIn descriptors: [ImageDescriptor],
        updating progress: Progress? = nil,
        completionHandler: @escaping (_ descriptor: ImageDescriptor,
                                      _ imageResult: Swift.Result<CompletionHandlerResult, Error>) -> Void
    ) async throws {
        let totalCount = Counter(count: descriptors.count) { count in
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        let completedCount = Counter(count: 0) { count in
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        
        for descriptor in descriptors {
            let requestedTime = descriptor.timecode.cmTimeValue
            let result = try await imageCompat(at: requestedTime)
            
            completedCount.increment()
            
            completionHandler(
                descriptor,
                .success(
                    CompletionHandlerResult(
                        image: result.image,
                        requestedTime: requestedTime,
                        actualTime: result.actualTime,
                        completedCount: completedCount.count,
                        totalCount: totalCount.count,
                        isFinished: completedCount.count == totalCount.count,
                        isFinishedIgnoreImage: false
                    )
                )
            )
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
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        
        for requestedTime in times {
            let result = try await imageCompat(at: requestedTime)
            
            completedCount.increment()
            
            completionHandler(
                requestedTime,
                .success(
                    CompletionHandlerResult(
                        image: result.image,
                        requestedTime: requestedTime,
                        actualTime: result.actualTime,
                        completedCount: completedCount.count,
                        totalCount: totalCount.count,
                        isFinished: completedCount.count == totalCount.count,
                        isFinishedIgnoreImage: false
                    )
                )
            )
        }
    }
                                  
    /// Backward-compatible implementation of Apple's `image(at time: CMTime)`.
    func imageCompat(at time: CMTime) async throws -> (image: CGImage, actualTime: CMTime) {
        if #available(macOS 13.0, *) {
            return try await image(at: time)
        }
        
        var resultImage: CGImage? = nil
        var resultError: Error? = nil
        var resultActualTime: CMTime? = nil
        
        let group = DispatchGroup()
        group.enter()
        
        let nsValue = NSValue(time: time)
        generateCGImagesAsynchronously(forTimes: [nsValue])
        { /*requestedTime*/ _, image, actualTime, /*result*/ _, error in
            resultImage = image
            resultError = error
            resultActualTime = actualTime
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            group.notify(queue: .main) {
                if let resultError {
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
