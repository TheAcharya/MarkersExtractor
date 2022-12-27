import Foundation
import OrderedCollections

public protocol MarkersExportPreparedMarker
    where Field: Hashable,
    Field: RawRepresentable,
    Field.RawValue == String
{
    associatedtype Field
    
    var imageFileName: String { get }
    
    func dictionaryRepresentation() -> OrderedDictionary<Field, String>
}
