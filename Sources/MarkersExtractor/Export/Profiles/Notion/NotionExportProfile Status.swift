//
//  NotionExportProfile Status.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

extension NotionExportProfile {
    enum Status: String, CaseIterable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case done = "Done"
        
        init(_ type: MarkerType) {
            switch type {
            case .standard:
                self = .notStarted
            case let .todo(completed):
                self = completed ? .done : .inProgress
            case .chapter:
                self = .notStarted
            }
        }
    }
}
