//
//  MarkerRole.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import DAWFileKit

/// Single Marker Role.
///
/// Note that role names cannot include a dot (`.`) or a question mark (`?`).
/// This is enforced by Final Cut Pro because they are reserved characters for encoding the string
/// in FCPXML.
public enum MarkerRole: Hashable, Equatable, Sendable {
    case video(_ roleFormattedForUserDisplay: String)
    case audio(_ roleFormattedForUserDisplay: String)
    case caption(_ roleFormattedForUserDisplay: String)
}

extension MarkerRole: CustomStringConvertible {
    public var description: String {
        stringValue
    }
    
    var stringValue: String {
        switch self {
        case let .video(string):
            return string
        case let .audio(string):
            return string
        case let .caption(string):
            return string
        }
    }
}

extension MarkerRole {
    var isVideo: Bool {
        guard case .video = self else {
            return false
        }
        return true
    }
    
    var isAudio: Bool {
        guard case .audio = self else {
            return false
        }
        return true
    }
    
    var isCaption: Bool {
        guard case .caption = self else {
            return false
        }
        return true
    }
}

extension Array where Element == MarkerRole {
    func flattenedString() -> String {
        map(\.stringValue)
            .joined(separator: ", ")
    }
}

// MARK: - MarkerRoleType

public enum MarkerRoleType: String, CaseIterable, Equatable, Hashable, Sendable {
    case video
    case audio
    case caption
}
