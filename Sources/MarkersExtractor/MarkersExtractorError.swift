//
//  MarkersExtractorError.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum MarkersExtractorError: LocalizedError {
    case validationError(String)
    case runtimeError(String)

    public var errorDescription: String? {
        switch self {
        case let .validationError(error):
            return "Validation error: \(error)"
        case let .runtimeError(error):
            return error
        }
    }
}
