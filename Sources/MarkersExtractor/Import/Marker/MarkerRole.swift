//
//  MarkerRole.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum MarkerRole: Hashable, Equatable {
    case video(String)
    case audio(String)
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
}

extension Array where Element == MarkerRole {
    func flattenedString() -> String {
        map { $0.stringValue }
            .joined(separator: ", ")
    }
}

// MARK: MarkerRoles

public struct MarkerRoles: Equatable, Hashable {
    public var video: String?
    public var audio: String?
    
    public init(
        video: String? = nil,
        audio: String? = nil,
        collapseSubroles: Bool = false
    ) {
        self.video = video
        self.audio = audio
        if collapseSubroles { self.collapseSubroles() }
    }
    
    /// Returns FCP's default role(s) for each clip type.
    /// FCP does not write the role to the XML when it does not have a custom role set and is using a default role.
    ///
    /// - Note: This does not cover all cases as clip type is not the only identifier
    ///   that can be used to determine clip role.
    ///
    /// - Parameter clipType: XML element name. ie: "title" for XML `<title ...>`
    /// - Returns: Role name string. Returns `nil` for unhandled/unrecognized clip types.
    public init?(defaultForClipType clipType: String) {
        switch clipType {
        case "asset-clip":
            self.init(video: "Video")
        case "title":
            self.init(video: "Titles")
        default:
            return nil
        }
    }
}

// MARK: - Methods

extension MarkerRoles {
    public var videoIsEmpty: Bool {
        video == nil || video?.isEmpty == true
    }
    
    public var audioIsEmpty: Bool {
        video == nil || video?.isEmpty == true
    }
    
    static let notAssignedRole = "Not Assigned"
    
    public func videoFormatted() -> String {
        if let video = video, !video.isEmpty {
            return video
        }
        return Self.notAssignedRole
    }
    
    public func audioFormatted() -> String {
        if let audio = audio, !audio.isEmpty {
            return audio
        }
        return Self.notAssignedRole
    }
}

// MARK: - Subroles

extension MarkerRoles {
    /// Strip off subrole if subrole is redundantly generated by FCP.
    /// ie: A role of "Role.Role-1" would return "Role"
    public mutating func collapseSubroles() {
        if let v = video {
            video = Self.collapseSubrole(role: v)
        }
        if let a = audio {
            audio = Self.collapseSubrole(role: a)
        }
    }
    
    /// Strip off subrole if subrole is redundantly generated by FCP.
    /// ie: A role of "Role.Role-1" would return "Role"
    public func collapsedSubroles() -> Self {
        var copy = self
        copy.collapseSubroles()
        return copy
    }
    
    /// Strip off subrole if subrole is redundantly generated by FCP.
    /// ie: A role of "Role.Role-1" would return "Role"
    static func collapseSubrole(role: String) -> String {
        let pattern = #"^(.*)\.(.*)-([\d]{1,3})$"#
        let matches = role.regexMatches(captureGroupsFromPattern: pattern)
        guard matches.count == 4,
              let role = matches[1],
              let subrole = matches[2]
                
        else { return role }
        
        if role == subrole { return role }
        return role
    }
}

// MARK: - MarkerRoleType

public enum MarkerRoleType: String, CaseIterable {
    case video
    case audio
}
