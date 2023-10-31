//
//  MarkerType.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

// https://support.apple.com/en-sg/guide/final-cut-pro/ver397279dd/mac

public enum MarkerType: Equatable, Hashable, Sendable {
    case standard
    case chapter
    case todo(completed: Bool)
}

extension MarkerType {
    public var name: String {
        switch self {
        case .standard: return "Standard"
        case .chapter: return "Chapter"
        case .todo: return "To Do"
        }
    }
}
