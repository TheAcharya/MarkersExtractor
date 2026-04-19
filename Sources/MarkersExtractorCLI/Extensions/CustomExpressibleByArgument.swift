//
//  CustomExpressibleByArgument.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser

/// Prevents ArgumentParser from writing out enum case allCases in the argument help.
protocol CustomExpressibleByArgument where Self: ExpressibleByArgument { }

extension CustomExpressibleByArgument {
    public static var allValueStrings: [String] {
        []
    }
}

func caseIterableValueString<R: RawRepresentable & CaseIterable>(
    for type: R.Type
) -> String where R.RawValue == String {
    R.allCases
        .map(\.rawValue)
        .joined(separator: " | ")
}
