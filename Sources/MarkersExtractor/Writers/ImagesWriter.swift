//
//  ImagesWriter.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKitCore

/// Generate still images on disk.
class ImagesWriter: ImageWriterProtocol { // TODO: refator as actor?
    let descriptors: [ImageDescriptor]
    let sourceMediaFile: URL
    let outputFolder: URL
    let imageFormat: MarkerImageFormat.Still
    /// Quality for compressed image formats (0.0 ... 1.0)
    let imageJPGQuality: Double
    let imageDimensions: CGSize?
    let imageLabelProperties: MarkerLabelProperties
    let logger: Logger
    
    let extractor: StillImageBatchExtractor
    
    // ProgressReporting / ImageWriterProtocol
    let progress: Progress
    
    init(
        descriptors: [ImageDescriptor],
        sourceMediaFile: URL,
        outputFolder: URL,
        imageFormat: MarkerImageFormat.Still,
        imageJPGQuality: Double,
        imageDimensions: CGSize?,
        imageLabelProperties: MarkerLabelProperties,
        logger: Logger? = nil
    ) {
        self.descriptors = descriptors
        self.sourceMediaFile = sourceMediaFile
        self.outputFolder = outputFolder
        self.imageFormat = imageFormat
        self.imageJPGQuality = imageJPGQuality
        self.imageDimensions = imageDimensions
        self.imageLabelProperties = imageLabelProperties
        self.logger = logger ?? Logger(label: "\(Self.self)")
        
        let conversion = StillImageBatchExtractor.ConversionSettings(
            descriptors: descriptors,
            sourceMediaFile: sourceMediaFile,
            outputFolder: outputFolder,
            frameFormat: imageFormat,
            jpgQuality: imageJPGQuality,
            dimensions: imageDimensions,
            imageFilter: { inputImage, label in
                if let label {
                    var labeler = ImageLabeler(
                        labelProperties: imageLabelProperties,
                        logger: logger
                    )
                    return labeler.labelImage(image: inputImage, text: label)
                } else {
                    return inputImage
                }
            }
        )
        
        extractor = StillImageBatchExtractor(conversion, logger: logger)
        progress = extractor.progress
    }
}

// MARK: - Methods

extension ImagesWriter {
    func write() async throws {
        do {
            let result = try await extractor.convert()
            // post errors to console if operation partially completed
            for error in await result.errors {
                let tc = error.descriptor.absoluteTimecode.stringValue()
                let filename = error.descriptor.filename.quoted
                let err = error.error.localizedDescription
                logger.warning(
                    "Error while generating image \(filename) for marker at \(tc): \(err)"
                )
            }
        } catch let err as StillImageBatchExtractorError {
            throw MarkersExtractorError.extraction(.image(.stillImage(err)))
        } catch {
            throw MarkersExtractorError.extraction(.image(.generic(
                "Error while generating images: \(error.localizedDescription)"
            )))
        }
    }
}
