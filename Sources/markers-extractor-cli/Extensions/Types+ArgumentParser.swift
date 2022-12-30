import ArgumentParser
import MarkersExtractor

// Export

extension ExportProfileFormat: ExpressibleByArgument {}
extension CSVExportProfile.Field: ExpressibleByArgument {}

// Markers

extension MarkerIDMode: ExpressibleByArgument {}
extension MarkerImageFormat: ExpressibleByArgument {}
extension MarkerLabelProperties.AlignHorizontal: ExpressibleByArgument {}
extension MarkerLabelProperties.AlignVertical: ExpressibleByArgument {}
