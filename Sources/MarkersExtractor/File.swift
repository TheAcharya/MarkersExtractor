import Foundation

public struct File {
    public var cache: FileCache?
    public var url: URL?
}

extension File {
    public enum FileCache {
        /// Pre-fetched file contents as `Data`.
        case data(Data)
        
        /// Pre-fetched file contents as `String`.
        case string(String)
    }
}

extension File {
   public var isFetched: Bool {
        cache != nil
    }
    
    /// Reads the data off disk and returns a new instance containing the cached data.
    /// If the current instance already contains cached data
    public func fetch(resetCache: Bool = false) throws -> Self {
        var copy = self
        
        if resetCache {
            copy.cache = nil
        }
        
        if cache != nil {
            return copy
        }
        
        guard let url = url else {
            throw MarkersExtractorError.runtimeError("File URL is missing while attempting to read file contents.")
        }
        
        let data = try Data(contentsOf: url)
        copy.cache = .data(data)
        return copy
    }
    
    public func data() throws -> Data {
        guard let fetched = try fetch().cache else {
            let u = url != nil ? "\(url!)" : "-"
            throw MarkersExtractorError.runtimeError("File \(u.quoted) could not be read.")
        }
        switch fetched {
        case .data(let data):
            return data
        case .string(let string):
            guard let data = string.data(using: .utf8) else {
                let u = url != nil ? "\(url!)" : "-"
                throw MarkersExtractorError.runtimeError("File \(u.quoted) could not be read.")
            }
            return data
        }
    }
}

// MARK: - Static Constructors

extension File {
    public static func url(_ url: URL) -> Self {
        File(cache: nil, url: url)
    }
    
    public static func data(_ data: Data) -> Self {
        File(cache: .data(data), url: nil)
    }
    
    public static func string(_ string: String) -> Self {
        File(cache: .string(string), url: nil)
    }
}
