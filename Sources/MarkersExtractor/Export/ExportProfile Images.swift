//
//  ExportProfile Images.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

extension ExportProfile {
    /// Generate animated images on disk.
    /// For the time being, the only format supported is Animated GIF.
    static func writeAnimatedImages(
        timecodes: OrderedDictionary<String, Timecode>,
        video videoPath: URL,
        outputURL: URL,
        gifFPS: Double,
        gifSpan: TimeInterval,
        gifDimensions: CGSize?,
        imageFormat: MarkerImageFormat.Animated,
        imageLabelText: [String],
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil,
        exportProfileProgress progress: Progress? = nil,
        progressUnitCount: Int64 = 0
    ) throws {
        let logger = logger ?? Logger(label: "\(Self.self)")
        
        var imageLabeler: ImageLabeler?
        
        if !imageLabelText.isEmpty {
            imageLabeler = ImageLabeler(
                labelText: imageLabelText,
                labelProperties: imageLabelProperties,
                logger: logger
            )
        }
        
        var filesProgress: Progress? = nil
        if let progress {
            filesProgress = Progress(
                totalUnitCount: Int64(timecodes.count),
                parent: progress,
                pendingUnitCount: progressUnitCount
            )
        }
        
        for (imageName, timecode) in timecodes {
            let outputURL = outputURL.appendingPathComponent(imageName)
            
            var delta = timecode
            delta.set(.realTime(seconds: gifSpan / 2), by: .clamping)
            
            let timeIn = timecode - delta
            let timeOut = timecode + delta
            let timeRange = timeIn ... timeOut
            
            imageLabeler?.nextText()
            
            let conversion = AnimatedImageExtractor.ConversionSettings(
                sourceMediaFile: videoPath,
                outputFolder: outputURL,
                timecodeRange: timeRange,
                dimensions: gifDimensions,
                outputFPS: gifFPS,
                imageFilter: imageLabeler?.labelImage,
                imageFormat: imageFormat
            )
            
            do {
                try AnimatedImageExtractor(conversion, logger: logger).convert()
            } catch let err as AnimatedImageExtractorError {
                throw MarkersExtractorError.extraction(.image(.animatedImage(err)))
            } catch {
                throw MarkersExtractorError.extraction(.image(.generic(
                    "Error while generating animated thumbnail \(outputURL.lastPathComponent.quoted):"
                        + " \(error.localizedDescription)"
                )))
            }
            
            filesProgress?.completedUnitCount += 1
        }
    }
    
    static func writeStillImages(
        timecodes: OrderedDictionary<String, Timecode>,
        video videoPath: URL,
        outputURL: URL,
        imageFormat: MarkerImageFormat.Still,
        imageJPGQuality: Double,
        imageDimensions: CGSize?,
        imageLabelText: [String],
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil,
        exportProfileProgress progress: Progress? = nil,
        progressUnitCount: Int64 = 0
    ) throws {
        let logger = logger ?? Logger(label: "\(Self.self)")
        
        var imageLabeler: ImageLabeler?
        
        if !imageLabelText.isEmpty {
            imageLabeler = ImageLabeler(
                labelText: imageLabelText,
                labelProperties: imageLabelProperties,
                logger: logger
            )
        }
        
        let conversion = ImageExtractor.ConversionSettings(
            sourceMediaFile: videoPath,
            outputFolder: outputURL,
            timecodes: timecodes,
            frameFormat: imageFormat,
            jpgQuality: imageJPGQuality,
            dimensions: imageDimensions,
            imageFilter: imageLabeler?.labelImageNextText
        )
        
        let extractor = ImageExtractor(conversion, logger: logger)
        progress?.addChild(extractor.progress, withPendingUnitCount: progressUnitCount)
        
        do {
            try extractor.convert()
        } catch let err as ImageExtractorError {
            throw MarkersExtractorError.extraction(.image(.staticImage(err)))
        } catch {
            throw MarkersExtractorError.extraction(.image(.generic(
                "Error while generating images: \(error.localizedDescription)"
            )))
        }
    }
}
