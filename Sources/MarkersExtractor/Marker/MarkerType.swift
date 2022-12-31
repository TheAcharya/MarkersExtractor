//
//  MarkerType.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

// https://support.apple.com/en-sg/guide/final-cut-pro/ver397279dd/mac

enum MarkerType: Equatable, Hashable {
    case standard
    case chapter
    case todo(completed: Bool)
}

extension MarkerType {
    var name: String {
        switch self {
        case .standard: return "Standard"
        case .chapter: return "Chapter"
        case .todo: return "To Do"
        }
    }
}
