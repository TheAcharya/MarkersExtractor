//
//  Types+ArgumentParser.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import MarkersExtractor
import DAWFileKit

// Export

extension ExportProfileFormat: CustomExpressibleByArgument { }
extension ExportField: CustomExpressibleByArgument { }
extension ExportFolderFormat: CustomExpressibleByArgument { }

// Markers

extension MarkerIDMode: CustomExpressibleByArgument { }
extension MarkerImageFormat: CustomExpressibleByArgument { }
extension MarkerLabelProperties.AlignHorizontal: CustomExpressibleByArgument { }
extension MarkerLabelProperties.AlignVertical: CustomExpressibleByArgument { }
extension MarkersSource: CustomExpressibleByArgument { }

// DAWFileKit Types

extension FinalCutPro.FCPXML.RoleType: CustomExpressibleByArgument { }

// CaseIterable suppression
// prevents ArgumentParser from writing out enum case allCases in the argument help.

protocol CustomExpressibleByArgument: ExpressibleByArgument { }

extension CustomExpressibleByArgument {
    public static var allValueStrings: [String] { [] }
}

func caseIterableValueString<R: RawRepresentable>(
    for type: R.Type
) -> String where R.RawValue == String, R: CaseIterable {
    R.allCases.map { $0.rawValue }.joined(separator: " | ")
}
