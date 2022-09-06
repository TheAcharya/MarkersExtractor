import AppKit

public struct MarkerLabelProperties {
    public enum AlignHorizontal: String, CaseIterable {
        case left
        case center
        case right
    }

    public enum AlignVertical: String, CaseIterable {
        case top
        case center
        case bottom
    }

    let fontName: String
    let fontMaxSize: Int
    let fontColor: NSColor
    let fontStrokeColor: NSColor
    let fontStrokeWidth: Int?
    let alignHorizontal: AlignHorizontal
    let alignVertical: AlignVertical
}
