//
//  NotionExportProfile Status.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation

extension NotionExportProfile {
    enum Status: String {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case done = "Done"
    }
}

extension NotionExportProfile.Status: Equatable { }

extension NotionExportProfile.Status: Hashable { }

extension NotionExportProfile.Status: CaseIterable { }

extension NotionExportProfile.Status: Sendable { }

// MARK: - Init

extension NotionExportProfile.Status {
    init(_ configuration: FinalCutPro.FCPXML.Marker.Configuration) {
        switch configuration {
        case .standard:
            self = .notStarted
        case .chapter:
            self = .notStarted
        case let .toDo(completed):
            self = completed ? .done : .inProgress
        }
    }
    
    init(_ type: InterpretedMarkerType) {
        switch type {
        case let .marker(markerConfiguration):
            self.init(markerConfiguration)
        case .caption:
            self = .notStarted
        }
    }
}
