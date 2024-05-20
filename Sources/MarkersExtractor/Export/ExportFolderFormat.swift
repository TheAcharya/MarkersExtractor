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
            return "\(projectName) \(nowTimestamp(twentyFourHour: true))"
        case .long:
            return "\(projectName) \(nowTimestamp(twentyFourHour: true)) [\(profile.name)]"
        }
    }
    
    private func nowTimestamp(twentyFourHour: Bool) -> String {
        let now = Date()
        let formatter = DateFormatter()
        if twentyFourHour {
            // "2024-03-20 14-45-10"
            formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        } else {
            // "2024-03-20 02-45-10PM"
            formatter.dateFormat = "yyyy-MM-dd hh-mm-ssa"
        }
        return formatter.string(from: now)
    }
}
