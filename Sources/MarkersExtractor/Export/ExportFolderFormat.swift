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
    func folderName(projectName: String, profile: ExportProfileFormat) -> String {
        switch self {
        case .short:
            return "\(projectName)"
        case .medium:
            return "\(projectName) \(nowTimestamp())"
        case .long:
            return "\(projectName) \(nowTimestamp()) [\(profile.name)]"
        }
    }
    
    private func nowTimestamp() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh-mm-ss"
        return formatter.string(from: now)
    }
}
