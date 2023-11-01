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
final class AnimatedImageExtractor: NSObject, ProgressReporting {
    // MARK: - Properties
    
    private let logger: Logger
    private var conversion: ConversionSettings
    
    private let asset: AVAsset
    private let videoTrackForThumbnails: AVAssetTrack
    private let frameRate: TimecodeFrameRate
    private let videoTrackRange: ClosedRange<Timecode>
    
    let startTime: TimeInterval
    let descriptors: [ImageDescriptor]
    
    // ProgressReporting
    let progress: Progress
    
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
        
        startTime = Self.timecodeRange(for: conversion, videoTrackRange: videoTrackRange)
            .lowerBound.realTimeValue
        descriptors = Self.generateDescriptors(
            for: conversion,
            videoTrackRange: videoTrackRange,
            frameRate: frameRate
        )
        
        progress = Progress()
    }
    
    private static func generateDescriptors(
        for conversion: ConversionSettings,
        videoTrackRange: ClosedRange<Timecode>,
        frameRate: TimecodeFrameRate
    ) -> [ImageDescriptor] {
        // TODO: needs some guards/validation in the event a LOT of frames are requested (such as an entire video length)
        
        // this process converts the source frame rate to the target frame rate
        // and uses the nearest source whole frame timecode for each destination frame
        
        let range = timecodeRange(for: conversion, videoTrackRange: videoTrackRange)
        let fd = frameDuration(for: conversion)
        
        let frameStride = stride(
            from: range.lowerBound.realTimeValue,
            through: range.upperBound.realTimeValue,
            by: fd
        )
        
        let timecodes = frameStride.map {
            Timecode(.realTime(seconds: $0), at: frameRate, by: .clamping)
        }
        
        // map to ImageDescriptor for richer error reporting
        let descriptors: [ImageDescriptor] = timecodes.map {
            // name and label are not used, just need to pack the timecode in
            ImageDescriptor(timecode: $0, filename: "Animation Frame", label: nil)
        }
        
        return descriptors
    }
    
    static func timecodeRange(
        for conversion: ConversionSettings,
        videoTrackRange: ClosedRange<Timecode>
    ) -> ClosedRange<Timecode> {
        conversion.timecodeRange ?? videoTrackRange
    }
    
    var timecodeRange: ClosedRange<Timecode> {
        Self.timecodeRange(for: conversion, videoTrackRange: videoTrackRange)
    }
    
    static func frameDuration(for conversion: ConversionSettings) -> TimeInterval {
        1.0 / conversion.outputFPS
    }
    
    var frameDuration: TimeInterval {
        Self.frameDuration(for: conversion)
    }
}

// MARK: - Convert

extension AnimatedImageExtractor {
    /// - Throws: ``AnimatedImageExtractorError`` in the event of an unrecoverable error.
    /// - Returns: ``AnimatedImageExtractorResult`` if the batch operation completed either fully or partially.
    func convert() async throws -> AnimatedImageExtractorResult {
        progress.completedUnitCount = 0
        progress.totalUnitCount = 1
        
        try validate()
        
        let result: AnimatedImageExtractorResult
        
        // only gif is supported for now, but more formats could be added in future
        switch conversion.imageFormat {
        case .gif:
            result = try await generateGIF()
        }
        
        progress.completedUnitCount = 1
        
        return result
    }
    
    // MARK: - Helpers
    
    private func validate() throws {
        // Even though we enforce a minimum of 3 fps (?) in the GUI, a source video could have lower
        // FPS, and we should allow that.
        conversion.outputFPS = conversion.outputFPS
            .clamped(to: MarkersExtractor.Settings.Validation.outputFPS)
        
        guard !descriptors.isEmpty else {
            throw AnimatedImageExtractorError.notEnoughFrames(descriptors.count)
        }
    }
    
    /// - Throws: ``AnimatedImageExtractorError`` in the event of an unrecoverable error.
    /// - Returns: ``AnimatedImageExtractorResult`` if the batch operation completed either fully or partially.
    private func generateGIF() async throws -> AnimatedImageExtractorResult {
        let frameProperties = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFUnclampedDelayTime as String: frameDuration
            ]
        ]
        
        let gifDestination = try initGIF(framesCount: descriptors.count)

        var batchResult = AnimatedImageExtractorResult()
        var isBatchFinished: Bool = false
        
        let generator = imageGenerator()
        
        // important: frame images generation is ok to do concurrently, but
        // the creation of the GIF (CGImageDestinationAddImage) must happen serially
        
        var images: [Fraction: CGImage] = [:]
        try await generator.images(forTimesIn: descriptors, updating: nil) { [weak self] descriptor, imageResult in
            guard let self = self else {
                batchResult.addError(for: descriptor, .internalInconsistency("No reference to image extractor."))
                return
            }

            do {
                let (image, isFinished) = try self.processFrame(
                    for: imageResult,
                    at: self.startTime
                )
                if let image {
                    // we have to use Fraction as dictionary key since CMTime is not hashable on older macOS versions
                    images[descriptor.timecode.cmTimeValue.fractionValue] = image
                }
                if isFinished { isBatchFinished = true }
            } catch let error as AnimatedImageExtractorError {
                batchResult.addError(for: descriptor, error)
            } catch {
                batchResult.addError(for: descriptor, .generateFrameFailed(error))
            }
        }
        
        // TODO: throw error if `isBatchFinished == false`?
        assert(isBatchFinished)
        
        // assemble GIF
        // we have to sort since images were generated concurrently and may be out of order
        // TODO: perform this as images are generated to improve performance
        for (_, image) in images.sorted(by: { $0.key.cmTimeValue < $1.key.cmTimeValue }) {
            CGImageDestinationAddImage(gifDestination, image, frameProperties as CFDictionary)
        }
        
        if !CGImageDestinationFinalize(gifDestination) {
            throw AnimatedImageExtractorError.gifFinalizationFailed
        }
        
        return batchResult
    }

    private func initGIF(framesCount: Int) throws -> CGImageDestination {
        let fileProperties = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: NSNumber(value: 0)
            ],
            kCGImagePropertyGIFHasGlobalColorMap as String: NSValue(nonretainedObject: true)
        ] as [String: Any]
        
        guard let destination = CGImageDestinationCreateWithURL(
            conversion.outputFile as CFURL,
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

    /// - Returns: CGImage, or `nil` if
    /// - Throws: ``AnimatedImageExtractorError``
    private func processFrame(
        for result: Result<AVAssetImageGenerator.CompletionHandlerResult, Swift.Error>,
        at startTime: TimeInterval
    ) throws -> (image: CGImage?, isFinished: Bool) {
        switch result {
        case let .success(result):
            // This happens if the last frame in the video failed to be generated.
            if result.isFinishedIgnoreImage {
                return (nil, true)
            }

            if result.completedCount == 1 {
                logger.trace("CGImage: \(result.image.debugInfo)")
            }

            // TODO: This is just a workaround. Look into the cause of this.
            // https://github.com/sindresorhus/Gifski/pull/262
            // Skip incorrect out-of-range frames.
            if result.actualTime.seconds < startTime {
                return (nil, result.isFinished)
            }

            let image = conversion.imageFilter?(result.image) ?? result.image

            assert(result.actualTime.seconds >= 0)
            
            return (image, result.isFinished)
            
        case let .failure(error):
            throw AnimatedImageExtractorError.generateFrameFailed(error)
        }
    }
}

// MARK: - Types

extension AnimatedImageExtractor {
    struct ConversionSettings {
        var timecodeRange: ClosedRange<Timecode>?
        let sourceMediaFile: URL
        let outputFile: URL
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

public struct AnimatedImageExtractorResult: Sendable {
    public var errors: [(descriptor: ImageDescriptor, error: AnimatedImageExtractorError)] = []
    
    init(errors: [(descriptor: ImageDescriptor, error: AnimatedImageExtractorError)] = []) {
        self.errors = errors
    }
    
    mutating func addError(for descriptor: ImageDescriptor, _ error: AnimatedImageExtractorError) {
        errors.append((descriptor: descriptor, error: error))
    }
}
