import Foundation

public protocol ExportField: RawRepresentable, Hashable
where RawValue == String {
    /// Human-readable name. Useful for column name in exported tabular data.
    var name: String { get }
}
