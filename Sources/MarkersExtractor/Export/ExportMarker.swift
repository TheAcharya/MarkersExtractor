import Foundation
import OrderedCollections

public protocol ExportMarker {
    associatedtype Field: ExportField
    
    var imageFileName: String { get }
    
    func dictionaryRepresentation() -> OrderedDictionary<Field, String>
}
