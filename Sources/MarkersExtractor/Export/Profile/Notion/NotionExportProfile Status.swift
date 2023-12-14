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
        
        init(_ configuration: FinalCutPro.FCPXML.Marker.MarkerConfiguration) {
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
}
