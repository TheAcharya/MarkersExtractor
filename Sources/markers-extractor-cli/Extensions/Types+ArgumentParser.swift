import ArgumentParser
import MarkersExtractor

// Export

extension MarkersExportFormat: ExpressibleByArgument {}
extension CSVExportModel.Field: ExpressibleByArgument {}

// Markers

extension MarkerIDMode: ExpressibleByArgument {}
extension MarkerImageFormat: ExpressibleByArgument {}
extension MarkerLabelProperties.AlignHorizontal: ExpressibleByArgument {}
extension MarkerLabelProperties.AlignVertical: ExpressibleByArgument {}
