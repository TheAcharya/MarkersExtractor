import Foundation

extension CSVExportModel {
    public struct Payload: MarkersExportModelPayload {
        let idMode: MarkerIDMode
        let csvPath: URL
    }
}
