//
//  MarkerRole.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation

/// Single Marker Role.
///
/// Note that role names cannot include a dot (`.`) or a question mark (`?`).
/// This is enforced by Final Cut Pro because they are reserved characters for encoding the string
/// in FCPXML.
public enum MarkerRole {
    case video(_ roleFormattedForUserDisplay: String)
    case audio(_ roleFormattedForUserDisplay: String)
    case caption(_ roleFormattedForUserDisplay: String)
}

extension MarkerRole: Equatable { }

extension MarkerRole: Hashable { }

extension MarkerRole: Identifiable {
    public var id: Self { self }
}

extension MarkerRole: CustomStringConvertible {
    public var description: String {
        stringValue
    }
}

extension MarkerRole: Sendable { }

// MARK: - Properties

extension MarkerRole {
    public var roleType: FinalCutPro.FCPXML.RoleType {
        switch self {
        case .video:
            return .video
        case .audio:
            return .audio
        case .caption:
            return .caption
        }
    }
    
    public var stringValue: String {
        switch self {
        case let .video(string):
            return string
        case let .audio(string):
            return string
        case let .caption(string):
            return string
        }
    }
    
    public var isVideo: Bool {
        guard case .video = self else {
            return false
        }
        return true
    }
    
    public var isAudio: Bool {
        guard case .audio = self else {
            return false
        }
        return true
    }
    
    public var isCaption: Bool {
        guard case .caption = self else {
            return false
        }
        return true
    }
}

// MARK: - Collection Methods

extension Array where Element == MarkerRole {
    func flattenedString(separator: String) -> String {
        map(\.stringValue)
            .joined(separator: separator)
    }
}
