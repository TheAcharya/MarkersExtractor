//
//  ExportFieldValue.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum ExportFieldValue: Equatable, Hashable, Sendable {
    case string(_ string: String)
    case array(_ array: [ExportFieldValue])
    case dictionary(_ dictionary: [String: ExportFieldValue])
}

// MARK: - Static Constructors

extension ExportFieldValue {
    public static func array(_ array: [String]) -> Self {
        .array(array.map { .string($0) })
    }
    
    public static func array(_ array: [[String]]) -> Self {
        .array(array.map { .array($0) })
    }
    
    public static func array(_ array: [[String: String]]) -> Self {
        .array(array.map { .dictionary($0) })
    }
}

extension ExportFieldValue {
    public static func dictionary(_ dictionary: [String: String]) -> Self {
        let mapped: [String: ExportFieldValue] = dictionary
            .mapValues { .string($0) }
        return .dictionary(mapped)
    }
    
    public static func dictionary(_ dictionary: [String: [String]]) -> Self {
        let mapped: [String: ExportFieldValue] = dictionary
            .mapValues { .array($0) }
        return .dictionary(mapped)
    }
    
    public static func dictionary(_ dictionary: [String: [String: String]]) -> Self {
        let mapped: [String: ExportFieldValue] = dictionary
            .mapValues { .dictionary($0) }
        return .dictionary(mapped)
    }
}

// MARK: - Encoding

extension ExportFieldValue: Codable {
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let string):
            try string.encode(to: encoder)
        case .array(let array):
            try array.encode(to: encoder)
        case .dictionary(let dictionary):
            try dictionary.encode(to: encoder)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        var lastError: Error?
        
        do {
            let string = try container.decode(String.self)
            self = .string(string)
            return
        } catch { lastError = error }
        
        do {
            let array = try container.decode([ExportFieldValue].self)
            self = .array(array)
            return
        } catch { lastError = error }
        
        do {
            let dictionary = try container.decode([String: ExportFieldValue].self)
            self = .dictionary(dictionary)
            return
        } catch { lastError = error }
        
        throw lastError ?? DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "No valid data type could be decoded."
            )
        )
    }
}
