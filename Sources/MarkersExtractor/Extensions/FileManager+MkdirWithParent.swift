import Foundation

extension FileManager {
    func fileExistsAndIsDirectory(_ path: String) -> Bool {
        var fileIsDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(
            atPath: path,
            isDirectory: &fileIsDirectory
        )
        return fileExists && fileIsDirectory.boolValue
    }

    func mkdirWithParent(_ path: String) throws {
        if fileExistsAndIsDirectory(path) {
            return
        }

        try FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
