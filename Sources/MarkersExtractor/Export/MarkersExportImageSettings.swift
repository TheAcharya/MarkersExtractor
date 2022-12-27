import AVFoundation
import Foundation

public struct MarkersExportImageSettings<Field>
where Field: Hashable,
      Field: RawRepresentable,
      Field.RawValue == String
{
    let gifFPS: Double
    let gifSpan: TimeInterval
    let format: MarkerImageFormat
    let quality: Double
    let dimensions: CGSize?
    let labelFields: [Field]
    let labelCopyright: String?
    let labelProperties: MarkerLabelProperties
}
