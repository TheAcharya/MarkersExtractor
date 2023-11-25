//
//  NotionExportProfile Status.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation

extension NotionExportProfile {
    enum Status: String, CaseIterable, Equatable, Hashable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case done = "Done"
        
        init(_ type: FinalCutPro.FCPXML.Marker.MarkerMetaData) {
            switch type {
            case .standard:
                self = .notStarted
            case .chapter:
                self = .notStarted
            case let .toDo(completed):
                self = completed ? .done : .inProgress
            }
        }
    }
}
