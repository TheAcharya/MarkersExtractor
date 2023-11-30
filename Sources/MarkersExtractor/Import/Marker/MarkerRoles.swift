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
    public func audioFormatted() -> String {
        if let audio = audio {
            let nonEmptyAudioRoles = audio.filter { !$0.rawValue.trimmed.isEmpty }
            
            switch nonEmptyAudioRoles.count {
            case 0: 
                return Self.notAssignedRoleString
            case 1:
                return nonEmptyAudioRoles.first?.rawValue ?? ""
            default: // case 2...:
                // FCP shows only subrole in its GUI for this joined list.
                // as a fallback, we'll use the full raw role string if subrole is missing.
                return nonEmptyAudioRoles
                    .map { $0.subRole ?? $0.rawValue }
                    .joined(separator: ", ")
            }
        }
        return Self.notAssignedRoleString
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
    
    /// FCP often writes built-in roles as lowercase strings
    /// (ie: "dialogue" or "dialogue.dialogue-1").
    /// This will title-cased these roles (ie: "Dialogue") to match FCP's display.
    public mutating func titleCaseBuiltInRoles() {
        if var audioRoles = audio {
            for index in audioRoles.indices {
                if audioRoles[index].isBuiltIn == true {
                    audioRoles[index] = audioRoles[index].titleCased()
                }
            }
            audio = audioRoles
        }
        
        if video?.isBuiltIn == true {
            video = video?.titleCased()
        }
        
        // don't title-case caption roles.
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
