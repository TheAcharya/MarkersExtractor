import Foundation

extension CSVExportModel {
    public struct Payload: MarkersExportModelPayload {
        let csvPath: URL
    }
}
