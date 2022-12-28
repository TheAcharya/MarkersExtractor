import Foundation

extension CSVExportModel {
    public struct Payload: MarkersExportPayload {
        let csvPath: URL
    }
}
