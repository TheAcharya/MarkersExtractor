//
//  AVAssetImageGenerator.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

// Code in this file is derived from:
// https://github.com/sindresorhus/Gifski/blob/main/Gifski/Utilities.swift
//
// MIT License
//
// © 2019 Sindre Sorhus <sindresorhus@gmail.com> (sindresorhus.com)
// © 2019 Kornel Lesiński <kornel@pngquant.org> (gif.ski)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
// associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
// NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

    // TODO: refactor as async/await encapsulating generateCGImageAsynchronously instead of using generateCGImagesAsynchronously
    // which will allow us to:
    // - pass in an ImageDescriptor instance instead of being limited to CMTime in the completion handler
    // - provide richer error reporting to the user
    // - allow the ability of cancelling the process before it's done
    // what is not clear about generateCGImagesAsynchronously is:
    // - does it afford any internal performance optimizations above just using generateCGImageAsynchronously, or is it merely a convenience?
    // - does it abort the batch if an error occurs? it appears that it doesn't. and we may want to have that ability.
    
    /// - Note: If you use ``CompletionHandlerResult/completedCount``, don't forget to update its
    /// usage in each `completionHandler` call as it can change if frames are skipped, for example, blank frames.
    func generateCGImagesAsynchronously(
        forTimePoints timePoints: [CMTime],
        updating progress: Progress? = nil,
        completionHandler: @escaping (_ time: CMTime, 
                                      _ imageResult: Swift.Result<CompletionHandlerResult, Error>) -> Void
    ) {
        let times = timePoints.map { NSValue(time: $0) }
        
        let totalCount = Counter(count: times.count) { count in
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        let completedCount = Counter(count: 0) { count in
            progress?.totalUnitCount = Int64(exactly: count) ?? 0
        }
        let decodeFailureFrameCount = Counter(count: 0)
        
        let baseErrorMessage = "Internal error while generating image."
        
        // TODO: When minimum OS requirements can bump to macOS 13, this can be refactored to use `images(for:)` which is recommended as per Apple docs.
        generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, result, error in
            switch result {
            case .succeeded:
                completedCount.increment()
                
                guard let image = image else {
                    var errorMsg = baseErrorMessage
                    if let error {
                        errorMsg += " \(error.localizedDescription)"
                    }
                    completionHandler(
                        requestedTime,
                        .failure(MarkersExtractorError.extraction(.image(.generic(errorMsg))))
                    )
                    return
                }
                
                completionHandler(
                    requestedTime,
                    .success(
                        CompletionHandlerResult(
                            image: image,
                            requestedTime: requestedTime,
                            actualTime: actualTime,
                            completedCount: completedCount.count,
                            totalCount: totalCount.count,
                            isFinished: completedCount.count == totalCount.count,
                            isFinishedIgnoreImage: false
                        )
                    )
                )
                
            case .failed:
                // Handles blank frames in the middle of the video.
                // TODO: Report the `xcrun` bug to Apple if it's still an issue in macOS 11.
                if let error = error as? AVError {
                    // Ugly workaround for when the last frame is a failure.
                    func finishWithoutImageIfNeeded() {
                        guard completedCount.count == totalCount.count else {
                            return
                        }
                        
                        guard let emptyImage: CGImage = .empty else {
                            let errorMsg = "\(baseErrorMessage) \(error.localizedDescription)"
                            completionHandler(
                                requestedTime,
                                .failure(MarkersExtractorError.extraction(.image(.generic(errorMsg))))
                            )
                            return
                        }
                        
                        completionHandler(
                            requestedTime,
                            .success(
                                CompletionHandlerResult(
                                    image: emptyImage,
                                    requestedTime: requestedTime,
                                    actualTime: actualTime,
                                    completedCount: completedCount.count,
                                    totalCount: totalCount.count,
                                    isFinished: true,
                                    isFinishedIgnoreImage: true
                                )
                            )
                        )
                    }
                    
                    // We ignore blank frames.
                    if error.code == .noImageAtTime {
                        totalCount.decrement()
                        print("No image at time. Completed: \(completedCount) Total: \(totalCount)")
                        finishWithoutImageIfNeeded()
                        break
                    }
                    
                    // macOS 11 (still an issue in macOS 11.2) started throwing “decode failed”
                    // error for some frames in screen recordings.
                    // As a workaround, we ignore these as the GIF seems fine still.
                    if error.code == .decodeFailed {
                        decodeFailureFrameCount.increment()
                        totalCount.decrement()
                        print("Decode failure. Completed: \(completedCount) Total: \(totalCount)")
                        finishWithoutImageIfNeeded()
                        break
                    }
                }
                
                if let error = error {
                    completionHandler(requestedTime, .failure(error))
                } else {
                    let error = MarkersExtractorError.extraction(.image(.generic(baseErrorMessage)))
                    completionHandler(requestedTime, .failure(error))
                }
                
            case .cancelled:
                completionHandler(requestedTime, .failure(CancellationError()))
                
            @unknown default:
                assertionFailure(
                    "AVAssetImageGenerator.generateCGImagesAsynchronously() received a new enum case. Please handle it."
                )
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
