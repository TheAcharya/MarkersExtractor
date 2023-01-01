//
//  MarkerRole.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum MarkerRole: Hashable, Equatable {
    case audio(String)
    case video(String)
}

extension MarkerRole: CustomStringConvertible {
    public var description: String {
        stringValue
    }
    
    var stringValue: String {
        switch self {
        case let .audio(string):
            return string
        case let .video(string):
            return string
        }
    }
}

extension MarkerRole {
    var isAudio: Bool {
        guard case .audio = self else {
            return false
        }
        return true
    }
    
    var isVideo: Bool {
        guard case .video = self else {
            return false
        }
        return true
    }
}

extension Array where Element == MarkerRole {
    func flattenedString() -> String {
        filter(\.isVideo)
            .map { $0.stringValue }
            .joined(separator: ", ")
    }
}
