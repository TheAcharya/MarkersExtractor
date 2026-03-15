//
//  ExportField.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Markers CSV fields (header column names).
public enum ExportField: String {
    case id
    case name
    case type
    case checked
    case status
    case notes
    case reel
    case scene
    case take
    case position
    case clipType
    case clipName
    case clipIn
    case clipOut
    case clipDuration
    case clipKeywords
    case videoRole
    case audioRole
    case eventName
    case projectName
    case libraryName
    case iconImage
    case imageFileName
    case image
    case xmlPath
}

extension ExportField: Equatable { }

extension ExportField: Hashable { }

extension ExportField: CaseIterable { }

extension ExportField: RawRepresentable { }

extension ExportField: Identifiable {
    public var id: Self {
        self
    }
}

extension ExportField: Sendable { }

// MARK: - Properties

extension ExportField {
    /// Human-readable name. Useful for column name in exported tabular data.
    public var name: String {
        switch self {
        case .id: "Marker ID"
        case .name: "Marker Name"
        case .type: "Marker Type"
        case .checked: "Checked"
        case .status: "Status"
        case .notes: "Notes"
        case .reel: "Reel"
        case .scene: "Scene"
        case .take: "Take"
        case .position: "Marker Position"
        case .clipType: "Clip Type"
        case .clipName: "Clip Name"
        case .clipIn: "Clip In"
        case .clipOut: "Clip Out"
        case .clipDuration: "Clip Duration"
        case .clipKeywords: "Clip Keywords"
        case .videoRole: "Video Role & Subrole"
        case .audioRole: "Audio Role & Subrole"
        case .eventName: "Event Name"
        case .projectName: "Project Name"
        case .libraryName: "Library Name"
        case .iconImage: "Icon Image"
        case .imageFileName: "Image Filename"
        case .image: "Image"
        case .xmlPath: "XML Path"
        }
    }
}
