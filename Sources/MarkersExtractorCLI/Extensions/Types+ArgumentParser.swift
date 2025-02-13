//
//  Types+ArgumentParser.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import MarkersExtractor
import DAWFileKit

// MARK: - Markers Extractor: Export

extension ExportProfileFormat: ExpressibleByArgument, CustomExpressibleByArgument { }
extension ExportField: ExpressibleByArgument, CustomExpressibleByArgument { }
extension ExportFolderFormat: ExpressibleByArgument, CustomExpressibleByArgument { }

// MARK: - Markers Extractor: Markers

extension MarkerIDMode: ExpressibleByArgument, CustomExpressibleByArgument { }
extension MarkerImageFormat: ExpressibleByArgument, CustomExpressibleByArgument { }
extension MarkerLabelProperties.AlignHorizontal: ExpressibleByArgument, CustomExpressibleByArgument { }
extension MarkerLabelProperties.AlignVertical: ExpressibleByArgument, CustomExpressibleByArgument { }
extension MarkersSource: ExpressibleByArgument, CustomExpressibleByArgument { }

// MARK: - DAWFileKit Types

// Note: Use of `@retroactive` is safe here since `RoleType` will never be
// conformed to ExpressibleByArgument in DAWFileKit.

extension FinalCutPro.FCPXML.RoleType: @retroactive ExpressibleByArgument, CustomExpressibleByArgument { }
