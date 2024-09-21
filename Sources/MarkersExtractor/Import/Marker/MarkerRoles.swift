//
//  MarkerRole.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import DAWFileKit

/// Marker Roles for an element.
///
/// Note that role names cannot include a dot (`.`) or a question mark (`?`).
/// This is enforced by Final Cut Pro because they are reserved characters for encoding the string
/// in FCPXML.
public struct MarkerRoles: Equatable, Hashable, Sendable {
    /// Video Role.
    public var video: FinalCutPro.FCPXML.VideoRole?
    public var isVideoDefault: Bool
    
    /// Audio Role(s).
    /// There can be more than one audio role for a clip.
    /// For example, Sync Clips may have multiple audio sources.
    public var audio: [FinalCutPro.FCPXML.AudioRole]?
    public var isAudioDefault: Bool
    
    /// Caption role.
    public var caption: FinalCutPro.FCPXML.CaptionRole?
    public var isCaptionDefault: Bool
    
    public init(
        video: FinalCutPro.FCPXML.VideoRole? = nil,
        isVideoDefault: Bool = false,
        audio: [FinalCutPro.FCPXML.AudioRole]? = nil,
        isAudioDefault: Bool = false,
        caption: FinalCutPro.FCPXML.CaptionRole? = nil,
        isCaptionDefault: Bool = false,
        collapseSubroles: Bool = false
    ) {
        if collapseSubroles {
            self.video = video?.collapsingSubRole()
        } else {
            self.video = video
        }
        self.isVideoDefault = isVideoDefault
        
        if collapseSubroles {
            self.audio = audio?.map { $0.collapsingSubRole() }
        } else {
            self.audio = audio
        }
        self.isAudioDefault = isAudioDefault
        
        // caption sub-roles can't be collapsed because they only have a main role
        self.caption = caption
        self.isCaptionDefault = isCaptionDefault
    }
    
    @_disfavoredOverload
    public init(
        video rawVideoRole: String? = nil,
        isVideoDefault: Bool = false,
        audio rawAudioRoles: [String]? = nil,
        isAudioDefault: Bool = false,
        caption rawCaptionRole: String? = nil,
        isCaptionDefault: Bool = false,
        collapseSubroles: Bool = false
    ) {
        var videoRole: FinalCutPro.FCPXML.VideoRole? = nil
        if let rawVideoRole = rawVideoRole {
            videoRole = FinalCutPro.FCPXML.VideoRole(rawValue: rawVideoRole)
        }
        
        var audioRoles: [FinalCutPro.FCPXML.AudioRole]? = nil
        if let rawAudioRoles = rawAudioRoles {
            audioRoles = rawAudioRoles.compactMap {
                FinalCutPro.FCPXML.AudioRole(rawValue: $0)
            }
        }
        
        var captionRole: FinalCutPro.FCPXML.CaptionRole? = nil
        if let rawCaptionRole = rawCaptionRole {
            captionRole = FinalCutPro.FCPXML.CaptionRole(rawValue: rawCaptionRole)
        }
        
        self.init(
            video: videoRole,
            isVideoDefault: isVideoDefault,
            audio: audioRoles,
            isAudioDefault: isAudioDefault,
            caption: captionRole,
            isCaptionDefault: isCaptionDefault,
            collapseSubroles: collapseSubroles
        )
    }
}

extension MarkerRoles: Identifiable {
    public var id: Self { self }
}

// MARK: - Convenience Properties

extension MarkerRoles {
    /// Has a non-empty video role.
    public var isVideoEmpty: Bool {
        video == nil || video?.rawValue.isEmpty == true
    }
    
    /// Has a defined (non-default) video role.
    public var isVideoDefined: Bool {
        !isVideoEmpty && !isVideoDefault
    }
    
    /// Has a non-empty audio role.
    public var isAudioEmpty: Bool {
        audio == nil || (audio?.allSatisfy { $0.rawValue.isEmpty } == true)
    }
    
    /// Has a defined (non-default) audio role.
    public var isAudioDefined: Bool {
        !isAudioEmpty && !isAudioDefault
    }
    
    /// Has a non-empty caption role.
    public var isCaptionEmpty: Bool {
        caption == nil || caption?.rawValue.isEmpty == true
    }
    
    /// Has a defined (non-default) caption role.
    public var isCaptionDefined: Bool {
        !isCaptionEmpty && !isCaptionDefault
    }
}

// MARK: - String Formatting

extension MarkerRoles {
    static let notAssignedRoleString = "Not Assigned"
    
    /// Video role formatted for user display.
    public func videoFormatted() -> String {
        if let video = video, !video.rawValue.isEmpty {
            return video.rawValue
        }
        return Self.notAssignedRoleString
    }
    
    /// Audio role formatted for user display.
    ///
    /// Returns a flat joined string as well as an array of the same roles.
    /// Do not use both, but use the one that is appropriate for the manifest output format.
    /// If a format does not support arrays (ie: CSV and TSV), use the flat string.
    /// If a format supports arrays (ie: JSON, XML, plist) use the array.
    public func audioFormatted(multipleRoleSeparator: String) -> (flat: String, array: [String]) {
        var audioRoles: [String] = audio?
            .filter { !$0.rawValue.trimmed.isEmpty }
            .map(\.rawValue) ?? []
        
        if audioRoles.isEmpty {
            audioRoles = [Self.notAssignedRoleString]
        }
        
        let flat = audioRoles
            .joined(separator: multipleRoleSeparator)
        
        return (flat: flat, array: audioRoles)
    }
    
    /// Caption role formatted for user display.
    public func captionFormatted() -> String {
        if let caption = caption, !caption.rawValue.isEmpty {
            // never use raw `captionFormat` string for user display, only use main role
            return caption.role
        }
        return Self.notAssignedRoleString
    }
}

extension MarkerRoles {
    public mutating func removeEmptyStrings() {
        audio?.removeAll(where: {
            $0.rawValue.trimmed.isEmpty
        })
        if audio?.isEmpty == true { audio = nil }
        
        if video?.rawValue.trimmed.isEmpty == true {
            video = nil
        }
        
        if caption?.rawValue.trimmed.isEmpty == true {
            caption = nil
        }
    }
    
    /// Process markers, performing post-extraction formatting.
    public mutating func process() {
        removeEmptyStrings()
        
        if var audioRoles = audio {
            for index in audioRoles.indices {
                audioRoles[index] = FCPXMLMarkerExtractor
                    .processExtractedRole(role: audioRoles[index])
            }
            audio = audioRoles
        }
        
        if let videoRole = video {
            video = FCPXMLMarkerExtractor
                .processExtractedRole(role: videoRole)
        }
        
        if let captionRole = caption {
            caption = FCPXMLMarkerExtractor
                .processExtractedRole(role: captionRole)
        }
    }
}

// MARK: - Subroles

extension MarkerRoles {
    /// Strip off subrole if subrole is redundantly generated by FCP.
    /// ie: A role of "Role.Role-1" would return "Role".
    /// Only applies to audio and video roles. Has no effect on caption roles.
    public mutating func collapseSubroles() {
        video = video?.collapsingSubRole()
        audio = audio?.map { $0.collapsingSubRole() }
        // caption roles can't be collapsed
    }
    
    /// Strip off subrole if subrole is redundantly generated by FCP.
    /// ie: A role of "Role.Role-1" would return "Role".
    /// Only applies to audio and video roles. Has no effect on caption roles.
    public func collapsedSubroles() -> Self {
        var copy = self
        copy.collapseSubroles()
        return copy
    }
}

// MARK: - Utilities

extension MarkerRoles {
    public func contains(roleNamed roleName: String) -> Bool {
        if audio?.contains(where: { $0.rawValue == roleName }) == true {
            return true
        }
        
        if video?.rawValue == roleName { return true }
        
        if caption?.rawValue == roleName { return true }
        
        return false
    }
    
    public func contains(roleWithAnyNameIn roleNames: some Sequence<String>) -> Bool {
        for roleName in roleNames {
            if contains(roleNamed: roleName) { return true }
        }
        return false
    }
}
