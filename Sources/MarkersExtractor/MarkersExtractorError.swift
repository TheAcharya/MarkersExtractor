//
//  MarkersExtractorError.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Errors thrown by ``MarkersExtractor``.
public enum MarkersExtractorError: LocalizedError {
    /// Validation error.
    case validation(_ validationError: ValidationError)
    
    /// Extraction error.
    case extraction(_ extractionError: ExtractionError)
    
    public var errorDescription: String? {
        switch self {
        case let .validation(validationError):
            return validationError.errorDescription
        case let .extraction(extractionError):
            return extractionError.errorDescription
        }
    }
}

extension MarkersExtractorError {
    /// Validation errors.
    /// Do not construct directly -- wrap in a ``MarkersExtractorError`` case instead.
    public enum ValidationError: LocalizedError {
        case unsupportedFileFormat(atPath: String?)
        case fcpxmldIsNotADirectory(atPath: String)
        case fileNotExists(atPath: String)
        case fontNotUsable(_ fontName: String)
        case invalidImageLabelStrokeWidth
        case invalidImageLabelFontOpacity
        case invalidImageHeight
        case invalidImageWidth
        case invalidImageSizePercent
        case invalidImageQuality
        case invalidOutputFPS
        
        public var errorDescription: String? {
            switch self {
            case let .unsupportedFileFormat(path):
                var msg = "Unsupported file format"
                if let path {
                    msg += ": \(path.quoted)."
                } else {
                    msg += "."
                }
                return msg
            case let .fcpxmldIsNotADirectory(path):
                return "Path to fcpxmld bundle is not a directory: \(path.quoted)."
            case let .fileNotExists(path):
                return "File does not exist at path: \(path.quoted)."
            case let .fontNotUsable(fontName):
                return "Cannot use font \(fontName.quoted)."
            case .invalidImageLabelStrokeWidth:
                return "--label-stroke-width must be a positive integer or 0."
            case .invalidImageLabelFontOpacity:
                let range = MarkersExtractor.Settings.Validation.imageLabelFontOpacity
                return "--label-font-opacity must be within \(range) range."
            case .invalidImageHeight:
                return "--image-height must be a positive integer."
            case .invalidImageWidth:
                return "--image-width must be a positive integer."
            case .invalidImageSizePercent:
                let range = MarkersExtractor.Settings.Validation.imageSizePercent
                return "--image-size-percent must be within \(range) range."
            case .invalidImageQuality:
                let range = MarkersExtractor.Settings.Validation.imageQuality
                return "--image-quality must be within \(range) range."
            case .invalidOutputFPS:
                let range = MarkersExtractor.Settings.Validation.outputFPS
                return "--gif-fps must be within \(range) range."
            }
        }
    }
    
    /// Extraction errors.
    /// Do not construct directly -- wrap in a ``MarkersExtractorError`` case instead.
    public enum ExtractionError: LocalizedError {
        case fcpxmlParse(_ message: String)
        case projectMissing(_ message: String)
        case noMediaFound(_ message: String)
        case fileRead(_ message: String)
        case fileWrite(_ message: String)
        case filePermission(_ message: String)
        case outputFolderAlreadyExists(_ message: String)
        case image(_ imageGenerationError: ImageGenerationError)
        case internalInconsistency(_ message: String)
        
        public var errorDescription: String? {
            switch self {
            case let .fcpxmlParse(message):
                return message
            case let .projectMissing(message):
                return message
            case let .noMediaFound(message):
                return message
            case let .fileRead(message):
                return message
            case let .fileWrite(message):
                return message
            case let .filePermission(message):
                return message
            case let .outputFolderAlreadyExists(message):
                return message
            case let .image(imageGenerationError):
                return imageGenerationError.errorDescription
            case let .internalInconsistency(message):
                return message
            }
        }
        
        /// Wrapper for image extraction errors.
        /// Do not construct directly -- wrap in a ``MarkersExtractorError`` case instead.
        public enum ImageGenerationError: LocalizedError {
            case staticImage(_ error: ImageExtractorError)
            case animatedImage(_ error: AnimatedImageExtractorError)
            case generic(_ message: String)
            
            public var errorDescription: String? {
                switch self {
                case let .staticImage(error):
                    return error.errorDescription
                case let .animatedImage(error):
                    return error.errorDescription
                case let .generic(message):
                    return message
                }
            }
        }
    }
}
