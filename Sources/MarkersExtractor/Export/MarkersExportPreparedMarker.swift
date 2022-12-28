import Foundation
import OrderedCollections

public protocol MarkersExportPreparedMarker {
    associatedtype Field: MarkersExportField
    
    var imageFileName: String { get }
    
    func dictionaryRepresentation() -> OrderedDictionary<Field, String>
}
