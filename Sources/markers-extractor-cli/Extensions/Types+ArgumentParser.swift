//
//  Types+ArgumentParser.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import MarkersExtractor
import DAWFileKit

// Export

extension ExportProfileFormat: ExpressibleByArgument { }
extension ExportField: ExpressibleByArgument { }
extension ExportFolderFormat: ExpressibleByArgument { }

// Markers

extension MarkerIDMode: ExpressibleByArgument { }
extension MarkerImageFormat: ExpressibleByArgument { }
extension MarkerLabelProperties.AlignHorizontal: ExpressibleByArgument { }
extension MarkerLabelProperties.AlignVertical: ExpressibleByArgument { }
extension MarkersSource: ExpressibleByArgument { }

// DAWFileKit Types

extension FinalCutPro.FCPXML.RoleType: ExpressibleByArgument { }
