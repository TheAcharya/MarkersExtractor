//
//  AnimatedImageExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

@preconcurrency import AVFoundation
import Foundation
import ImageIO
import Logging
import TimecodeKitCore

/// Extract a sequence of frames from a video asset and produce an animated image (such as animated
/// GIF).
final actor AnimatedImageExtractor {
    // MARK: - Properties
    
    private let logger: Logger
    private var conversion: ConversionSettings
    
    private let asset: AVAsset
    private let videoTrackForThumbnails: AVAssetTrack
    private let frameRate: TimecodeFrameRate
    private let videoTrackRange: ClosedRange<Timecode>
    
    let startTime: TimeInterval
    let descriptors: [ImageDescriptor]
    
    // ProgressReporting (omitted protocol conformance as it would force NSObject inheritance)
    let progress: Progress
    
    // MARK: - Init
    
    /// - Throws: ``AnimatedImageExtractorError``
    init(_ conversion: ConversionSettings, logger: Logger? = nil) async throws {
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
            frameRate = try await asset.timecodeFrameRate()
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
            let dur = try await videoTrackForThumbnails.durationTimecode(at: frameRate)
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
}

// MARK: - Public Methods

extension AnimatedImageExtractor {
    /// - Throws: ``AnimatedImageExtractorError`` in the event of an unrecoverable error.
    /// - Returns: ``AnimatedImageExtractorResult`` if the batch operation completed either fully or
    /// partially.
    func convert() async throws -> BatchResult {
        progress.completedUnitCount = 0
        progress.totalUnitCount = 1
        
        try validate()
        
        let result: BatchResult
        
        // only gif is supported for now, but more formats could be added in future
        switch conversion.imageFormat {
        case .gif:
            result = try await generateGIF()
        }
        
        progress.completedUnitCount = 1
        
        return result
    }
}

// MARK: - Helpers

extension AnimatedImageExtractor {
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
    /// - Returns: ``AnimatedImageExtractorResult`` if the batch operation completed either fully or
    /// partially.
    private func generateGIF() async throws -> BatchResult {
        let frameProperties = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFUnclampedDelayTime as String: frameDuration
            ]
        ]
        
        let gifDestination = try initGIF(framesCount: descriptors.count)

        let batchResult = BatchResult()
        
        let generator = imageGenerator()
        
        // important: frame images generation is ok to do concurrently, but
        // the creation of the GIF (CGImageDestinationAddImage) must happen serially
        
        let images: [Fraction: CGImage] = try await generator.images(
            forTimesIn: descriptors, 
            updating: nil
        ) { [weak self, batchResult] descriptor, image, result in
            guard let self = self else {
                await batchResult.addError(
                    for: descriptor,
                    .internalInconsistency("No reference to image extractor.")
                )
                return
            }
            
            do {
                let (processedImage, isFinished) = try await self.processFrame(
                    image: image,
                    result: result,
                    at: self.startTime
                )
                if isFinished { await batchResult.setFinished() }
                
                if let processedImage {
                    image = processedImage
                }
            } catch let error as AnimatedImageExtractorError {
                await batchResult.addError(for: descriptor, error)
            } catch {
                await batchResult.addError(for: descriptor, .generateFrameFailed(error))
            }
        }
        
        // TODO: throw error if `isBatchFinished == false`?
        let isFinished = await batchResult.isBatchFinished
        assert(isFinished)
        
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
            UTType.gif.identifier as CFString,
            framesCount,
            nil
        ) else {
            throw AnimatedImageExtractorError.gifInitializationFailed
        }

        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        return destination
    }

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

    /// - Returns: CGImage, or `nil`.
    /// - Throws: ``AnimatedImageExtractorError``
    private func processFrame(
        image: CGImage,
        result: Result<AVAssetImageGeneratorWrapper.CompletionHandlerResult, Swift.Error>,
        at startTime: TimeInterval
    ) throws -> (image: CGImage?, isFinished: Bool) {
        switch result {
        case let .success(result):
            // This happens if the last frame in the video failed to be generated.
            if result.isFinishedIgnoreImage {
                return (nil, true)
            }

            if result.completedCount == 1 {
                logger.trace("CGImage: \(image.debugInfo)")
            }

            // TODO: This is just a workaround. Look into the cause of this.
            // https://github.com/sindresorhus/Gifski/pull/262
            // Skip incorrect out-of-range frames.
            if result.actualTime.seconds < (startTime - 0.1) { // allow for small variances
                return (nil, result.isFinished)
            }
            
            let image = conversion.imageFilter?(image) ?? image

            // assert(result.actualTime.seconds >= 0)
            
            return (image, result.isFinished)
            
        case let .failure(error):
            throw AnimatedImageExtractorError.generateFrameFailed(error)
        }
    }
    
    var timecodeRange: ClosedRange<Timecode> {
        Self.timecodeRange(for: conversion, videoTrackRange: videoTrackRange)
    }
    
    var frameDuration: TimeInterval {
        Self.frameDuration(for: conversion)
    }
}

// MARK: - Static

extension AnimatedImageExtractor {
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
            ImageDescriptor(
                absoluteTimecode: $0,
                offsetFromVideoStart: $0,
                filename: "Animation Frame",
                label: nil
            )
        }
        
        return descriptors
    }
    
    static func timecodeRange(
        for conversion: ConversionSettings,
        videoTrackRange: ClosedRange<Timecode>
    ) -> ClosedRange<Timecode> {
        conversion.timecodeRange ?? videoTrackRange
    }
    
    static func frameDuration(for conversion: ConversionSettings) -> TimeInterval {
        1.0 / conversion.outputFPS
    }
}
