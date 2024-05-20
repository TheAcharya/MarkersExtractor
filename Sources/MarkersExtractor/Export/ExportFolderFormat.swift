//
//  ExportFolderFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum ExportFolderFormat: String, CaseIterable, Equatable, Hashable {
    case short
    case medium
    case long
}

extension ExportFolderFormat {
    func folderName(timelineName: String, profile: ExportProfileFormat) -> String {
        switch self {
        case .short:
            return "\(timelineName)"
        case .medium:
            return "\(timelineName) \(nowTimestamp())"
        case .long:
            return "\(timelineName) \(nowTimestamp()) [\(profile.name)]"
        }
    }
    
    private func nowTimestamp() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh-mm-ss"
        return formatter.string(from: now)
    }
}
