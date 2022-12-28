import Foundation

public struct FCPXMLFile {
    var file: File
    
    public init(_ file: File) {
        self.file = file
    }
}

extension FCPXMLFile: CustomStringConvertible {
    public var description: String {
        if let url = file.url {
            return "\(url)"
        }
        
        if file.cache != nil {
            return "FCP XML Data"
        }
        
        return "Missing FCPXML(D) File or Data Contents"
    }
}

extension FCPXMLFile {
    /// fcpxml(d) file/bundle URL.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var url: URL? {
        file.url
    }
    
    /// Returns the directory that contains the fcpxml(d) file/bundle.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var parentDir: URL? {
        file.url?.deletingLastPathComponent()
    }
    
    /// Resolves the location of the actual XML file.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var xmlPath: URL? {
        guard let url = file.url else {
            // not an error condition; file contents may be cached and no URL is present
            return nil
        }
        
        return url.fileExtension.caseInsensitiveCompare("fcpxmld") == .orderedSame
            ? url.appendingPathComponent("Info.fcpxml")
            : url
    }
    
    var defaultMediaSearchPath: URL? {
        file.url?.deletingLastPathComponent()
    }
}
