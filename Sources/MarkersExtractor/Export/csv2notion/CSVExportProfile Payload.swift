import Foundation

extension CSVExportProfile {
    public struct Payload: ExportPayload {
        let csvPath: URL
    }
}
