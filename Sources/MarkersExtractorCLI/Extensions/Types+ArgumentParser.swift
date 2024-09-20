//
//  Types+ArgumentParser.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import MarkersExtractor
import DAWFileKit

// MARK: - Markers Extractor: Export

// Note: Use of `@retroactive` is safe here since we control these types within the package,
// however they are in a different module. To suppress Xcode 16's build warning we can add `@retroactive`.

extension ExportProfileFormat: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }
extension ExportField: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }
extension ExportFolderFormat: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }

// MARK: - Markers Extractor: Markers

// Note: Use of `@retroactive` is safe here since we control these types within the package,
// however they are in a different module. To suppress Xcode 16's build warning we can add `@retroactive`.

extension MarkerIDMode: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }
extension MarkerImageFormat: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }
extension MarkerLabelProperties.AlignHorizontal: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }
extension MarkerLabelProperties.AlignVertical: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }
extension MarkersSource: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }

// MARK: - DAWFileKit Types

// Note: Use of `@retroactive` is safe here since `RoleType` will never be
// conformed to ExpressibleByArgument in DAWFileKit.

extension FinalCutPro.FCPXML.RoleType: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }

// MARK: - CaseIterable suppression
// prevents ArgumentParser from writing out enum case allCases in the argument help.

protocol CustomExpressibleByArgument where Self: ExpressibleByArgument { }

extension CustomExpressibleByArgument {
    public static var allValueStrings: [String] { [] }
}

func caseIterableValueString<R: RawRepresentable>(
    for type: R.Type
) -> String where R.RawValue == String, R: CaseIterable {
    R.allCases
        .map { $0.rawValue }
        .joined(separator: " | ")
}
