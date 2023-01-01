//
//  Types+ArgumentParser.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import MarkersExtractor

// Export

extension ExportProfileFormat: ExpressibleByArgument { }
extension StandardExportField: ExpressibleByArgument { }

// Markers

extension MarkerIDMode: ExpressibleByArgument { }
extension MarkerImageFormat: ExpressibleByArgument { }
extension MarkerLabelProperties.AlignHorizontal: ExpressibleByArgument { }
extension MarkerLabelProperties.AlignVertical: ExpressibleByArgument { }
