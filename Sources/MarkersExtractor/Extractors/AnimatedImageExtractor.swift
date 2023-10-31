//
//  AnimatedImageExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import ImageIO
import Foundation
import Logging
import TimecodeKit

/// Extract a sequence of frames from a video asset and produce an animated image (such as animated GIF).
final class AnimatedImageExtractor {
    // MARK: - Properties
    
    private let logger: Logger
    private var conversion: ConversionSettings
    
    private let asset: AVAsset
    private let videoTrackForThumbnails: AVAssetTrack
    private let frameRate: TimecodeFrameRate
    private let videoTrackRange: ClosedRange<Timecode>
    
    // MARK: - Init
    
    /// - Throws: ``AnimatedImageExtractorError``
    init(_ conversion: ConversionSettings, logger: Logger? = nil) throws {
        self.logger = logger ?? Logger(label: "\(AnimatedImageExtractor.self)")
        
        self.conversion = conversion
        asset = AVAsset(url: conversion.sourceMediaFile)
        
        // parse video asset
        
        guard asset.isReadable else {
            // This can happen if the user selects a file, and then the file becomes
            // unavailable or deleted before the "Convert" button is clicked.
            throw AnimatedImageExtractorError.unreadableFile
        }
        
        guard let videoTrack = asset.firstVideoTrack else {
            throw AnimatedImageExtractorError.noVideoTracks
        }
        videoTrackForThumbnails = videoTrack
        
        do {
            frameRate = try asset.timecodeFrameRate()
        } catch {
            throw AnimatedImageExtractorError.couldNotDetermineFrameRate(error)
        }
        
        // We use the duration of the first video track since the total duration of the asset
        // can actually be longer than the video track. If we use the total duration and the
        // video is shorter, we'll get errors in `generateCGImagesAsynchronously` (#119).
        // We already extract the video into a new asset in `VideoValidator` if the first
        // video track is shorter than the asset duration, so the handling here is not
        // strictly necessary but kept just to be safe.
        do {
            let dur = try videoTrackForThumbnails.durationTimecode(at: frameRate)
            videoTrackRange = Timecode(.zero, at: frameRate) ... dur
        } catch {
            throw AnimatedImageExtractorError.couldNotDetermineVideoTrackDuration(error)
        }
    }
}

// MARK: - Convert

extension AnimatedImageExtractor {
    /// - Throws: ``AnimatedImageExtractorError``
    func convert() async throws {
        validate()
        
        // only gif is supported for now, but more formats could be added in future
        switch conversion.imageFormat {
        case .gif:
            try await generateGIF()
        }
    }
    
    // MARK: - Helpers
    
    private func validate() {
        // Even though we enforce a minimum of 3 fps (?) in the GUI, a source video could have lower
        // FPS, and we should allow that.
        conversion.outputFPS = conversion.outputFPS
            .clamped(to: MarkersExtractor.Settings.Validation.outputFPS)
    }
    
    /// - Throws: ``AnimatedImageExtractorError``
    private func generateGIF() async throws {
        let generator = imageGenerator()
        
        // TODO: this is potentially very inefficient in the event that a LOT of frames are requested (such as an entire video length)
        
        // this process converts the source frame rate to the target frame rate
        // and uses the nearest source whole frame timecode for each destination frame
        
        let timeRange = conversion.timecodeRange ?? videoTrackRange

        let startTime = timeRange.lowerBound.realTimeValue
        let frameDuration: TimeInterval = 1.0 / conversion.outputFPS
        
        let frameStride = stride(
            from: timeRange.lowerBound.realTimeValue,
            through: timeRange.upperBound.realTimeValue,
            by: frameDuration
        )
        
        let times = frameStride
            .map { Timecode(.realTime(seconds: $0), at: frameRate, by: .clamping) }
            .map(\.cmTimeValue)
        
        let frameProperties = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFUnclampedDelayTime as String: frameDuration
            ]
        ]
        
        let gifDestination = try initGIF(framesCount: times.count)

        var result: Result<Void, AnimatedImageExtractorError> = .failure(
            .internalInconsistency("Image generation could not start.")
        )

        let group = DispatchGroup()
        
        let proposedImageCount = times.count
        for _ in 0 ..< proposedImageCount { group.enter() }

        generator.generateCGImagesAsynchronously(forTimePoints: times) { [weak self] imageResult in
            defer { group.leave() }
            
            guard let self = self else {
                result = .failure(.internalInconsistency("No reference to image extractor."))
                return
            }

            do {
                let isFinished = try self.processFrame(
                    for: imageResult,
                    at: startTime,
                    destination: gifDestination,
                    frameProperties: frameProperties as CFDictionary
                )
                if isFinished {
                    result = .success(())
                }
            } catch let error as AnimatedImageExtractorError {
                result = .failure(error)
            } catch {
                result = .failure(.generateFrameFailed(error))
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            group.notify(queue: .main) {
                if !CGImageDestinationFinalize(gifDestination) {
                    continuation.resume(
                        throwing: AnimatedImageExtractorError.gifFinalizationFailed
                    )
                }
                continuation.resume(with: result)
            }
        }
    }

    private func initGIF(framesCount: Int) throws -> CGImageDestination {
        let fileProperties = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: NSNumber(value: 0)
            ],
            kCGImagePropertyGIFHasGlobalColorMap as String: NSValue(nonretainedObject: true)
        ] as [String: Any]

        guard let destination = CGImageDestinationCreateWithURL(
            conversion.outputFolder as CFURL,
            kUTTypeGIF,
            framesCount,
            nil
        ) else {
            throw AnimatedImageExtractorError.gifInitializationFailed
        }

        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        return destination
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

    /// - Returns: `true` if finished.
    /// - Throws: ``AnimatedImageExtractorError``
    private func processFrame(
        for result: Result<AVAssetImageGenerator.CompletionHandlerResult, Swift.Error>,
        at startTime: TimeInterval,
        destination: CGImageDestination,
        frameProperties: CFDictionary
    ) throws -> Bool {
        switch result {
        case let .success(result):
            // This happens if the last frame in the video failed to be generated.
            if result.isFinishedIgnoreImage {
                return true
            }

            if result.completedCount == 1 {
                logger.trace("CGImage: \(result.image.debugInfo)")
            }

            // TODO: This is just a workaround. Look into the cause of this.
            // https://github.com/sindresorhus/Gifski/pull/262
            // Skip incorrect out-of-range frames.
            if result.actualTime.seconds < startTime {
                return false
            }

            let image = conversion.imageFilter?(result.image) ?? result.image

            let frameNumber = result.completedCount - 1
            assert(result.actualTime.seconds > 0 || frameNumber == 0)

            CGImageDestinationAddImage(destination, image, frameProperties)

            return result.isFinished
            
        case let .failure(error):
            throw AnimatedImageExtractorError.generateFrameFailed(error)
        }
    }
}

// MARK: - Types

extension AnimatedImageExtractor {
    struct ConversionSettings {
        let sourceMediaFile: URL
        let outputFolder: URL
        var timecodeRange: ClosedRange<Timecode>?
        var dimensions: CGSize?
        var outputFPS: Double
        let imageFilter: ((CGImage) -> CGImage)?
        let imageFormat: MarkerImageFormat.Animated
    }
}

/// Animated image extraction error.
public enum AnimatedImageExtractorError: LocalizedError {
    case internalInconsistency(_ verboseError: String)
    case unreadableFile
    case noVideoTracks
    case couldNotDetermineFrameRate(Error)
    case couldNotDetermineVideoTrackDuration(Error)
    case gifInitializationFailed
    case gifFinalizationFailed
    case notEnoughFrames(Int)
    case generateFrameFailed(Swift.Error)
    case addFrameFailed(Swift.Error)
    case writeFailed(Swift.Error)
    
    public var errorDescription: String? {
        switch self {
        case let .internalInconsistency(verboseError):
            return "Internal error occurred: \(verboseError)"
        case .unreadableFile:
            return "The selected file is no longer readable."
        case .noVideoTracks:
            return "The media file does not contain a video track."
        case let .couldNotDetermineFrameRate(error):
            return "Could not determine the media file's frame rate. \(error.localizedDescription)"
        case let .couldNotDetermineVideoTrackDuration(error):
            return "Could not determine the media file's video track duration. \(error.localizedDescription)"
        case .gifInitializationFailed:
            return "Failed to initialize GIF file."
        case .gifFinalizationFailed:
            return "Failed to finalize GIF file."
        case let .notEnoughFrames(frameCount):
            let framesString = "\(frameCount) frame\(frameCount == 1 ? "" : "s")"
            return "An animated GIF requires a minimum of 2 frames but the video contains \(framesString)."
        case let .generateFrameFailed(error):
            return "Failed to generate frame: \(error.localizedDescription)"
        case let .addFrameFailed(error):
            return "Failed to add frame, with underlying error: \(error.localizedDescription)"
        case let .writeFailed(error):
            return "Failed to write, with underlying error: \(error.localizedDescription)"
        }
    }
}
