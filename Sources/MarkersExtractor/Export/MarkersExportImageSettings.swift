import AVFoundation
import Foundation

public struct MarkersExportImageSettings<Field> {
    public let gifFPS: Double
    public let gifSpan: TimeInterval
    public let format: MarkerImageFormat
    public let quality: Double
    public let dimensions: CGSize?
    public let labelFields: [Field]
    public let labelCopyright: String?
    public let labelProperties: MarkerLabelProperties
    public let imageLabelHideNames: Bool
}
