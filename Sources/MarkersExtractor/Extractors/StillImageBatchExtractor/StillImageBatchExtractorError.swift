//
//  StillImageBatchExtractorError.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Still image extraction error.
public enum StillImageBatchExtractorError: LocalizedError {
    case internalInconsistency(_ verboseError: String)
    case unreadableFile
    case unsupportedType
    case generateFrameFailed(Swift.Error)
    case addFrameFailed(Swift.Error)
    case writeFailed(Swift.Error)
    
    public var errorDescription: String? {
        switch self {
        case let .internalInconsistency(verboseError):
            return "Internal error occurred: \(verboseError)"
        case .unreadableFile:
            return "The selected file is no longer readable."
        case .unsupportedType:
            return "Image type is not supported."
        case let .generateFrameFailed(error):
            return "Failed to generate frame: \(error.localizedDescription)"
        case let .addFrameFailed(error):
            return "Failed to add frame, with underlying error: \(error.localizedDescription)"
        case let .writeFailed(error):
            return "Failed to write, with underlying error: \(error.localizedDescription)"
        }
    }
}
