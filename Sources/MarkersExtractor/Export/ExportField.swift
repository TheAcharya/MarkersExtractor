//
//  ExportField.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Markers CSV fields (header column names).
public enum ExportField: String, CaseIterable, RawRepresentable, Hashable {
    case id
    case name
    case type
    case checked
    case status
    case notes
    case position
    case clipType
    case clipName
    case clipDuration
    case videoRole
    case audioRole
    case eventName
    case projectName
    case libraryName
    case iconImage
    case imageFileName
}

extension ExportField {
    /// Human-readable name. Useful for column name in exported tabular data.
    public var name: String {
        switch self {
        case .id: return "Marker ID"
        case .name: return "Marker Name"
        case .type: return "Marker Type"
        case .checked: return "Checked"
        case .status: return "Status"
        case .notes: return "Notes"
        case .position: return "Marker Position"
        case .clipType: return "Clip Type"
        case .clipName: return "Clip Name"
        case .clipDuration: return "Clip Duration"
        case .videoRole: return "Video Role & Subrole"
        case .audioRole: return "Audio Role & Subrole"
        case .eventName: return "Event Name"
        case .projectName: return "Project Name"
        case .libraryName: return "Library Name"
        case .iconImage: return "Icon Image"
        case .imageFileName: return "Image Filename"
        }
    }
}
