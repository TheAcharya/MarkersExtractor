import Cocoa
import CoreText
import Foundation
import Logging

class ImageLabeler {
    private let logger = Logger(label: "\(ImageLabeler.self)")

    private var fontSizeCache: [[String]: CGFloat] = [:]
    private var curText: String? = nil

    let properties: MarkerLabelProperties
    var textIter: IndexingIterator<[String]>

    init(labelText: [String], labelProperties: MarkerLabelProperties) {
        properties = labelProperties

        textIter = labelText.makeIterator()
    }

    func labelImage(image: CGImage) -> CGImage {
        guard let textToDraw = curText else {
            logger.warning("No label to mark image. Bypassing original image.")
            return image
        }

        guard let context = initImageContext(for: image) else {
            logger.warning("Failed to initialize new image context. Bypassing original image.")
            return image
        }

        let textRect = initTextRect(for: image)

        // Draw original image on background
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
        )

        drawText(text: textToDraw, context: context, textRect: textRect)

        guard let newImage = context.makeImage() else {
            logger.warning("Failed to create labeled image. Bypassing original image.")
            return image
        }

        return newImage
    }

    func labelImageNextText(image: CGImage) -> CGImage {
        nextText()
        return labelImage(image: image)
    }

    func nextText() {
        curText = textIter.next()
        if curText == nil {
            logger.warning("No more labels for marking images.")
        }
    }

    private func initImageContext(for image: CGImage) -> CGContext? {
        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else {
            logger.warning("Failed to initialize color space for image context.")
            return nil
        }

        return CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: image.bytesPerRow,
            space: colorSpace,
            bitmapInfo: image.bitmapInfo.rawValue
        )
    }

    private func initTextRect(for image: CGImage) -> CGRect {
        let padding = Int(Double(min(image.width, image.height)) * 0.05)

        return CGRect(
            x: padding,
            y: padding,
            width: image.width - 2 * padding,
            height: image.height - 2 * padding
        )
    }

    private func drawText(text: String, context: CGContext, textRect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()

        switch properties.alignHorizontal {
        case .right:
            paragraphStyle.alignment = .right
        case .center:
            paragraphStyle.alignment = .center
        case .left:
            paragraphStyle.alignment = .left
        }

        var stringAttributes: [NSAttributedString.Key: Any] = [
            .strokeColor: properties.fontStrokeColor,
            .foregroundColor: properties.fontColor,
            .paragraphStyle: paragraphStyle,
        ]

        let fontSize = calcFontSize(
            for: text,
            attributes: stringAttributes,
            restraint: textRect.size
        )

        stringAttributes[.font] = NSFont(name: properties.fontName, size: fontSize)
        if let strokeWidth = properties.fontStrokeWidth {
            stringAttributes[.strokeWidth] = Float(strokeWidth)
        } else {
            stringAttributes[.strokeWidth] = max(fontSize * 0.1, 4.0)
        }

        let shadow = NSShadow()
        shadow.shadowColor = properties.fontStrokeColor
        shadow.shadowOffset = CGSize(width: 0, height: 0)
        shadow.shadowBlurRadius = 2

        stringAttributes[.shadow] = shadow

        let attributedString = NSAttributedString(
            string: text,
            attributes: stringAttributes as [NSAttributedString.Key: Any]
        )

        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)

        let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(
            frameSetter,
            CFRangeMake(0, attributedString.string.count),
            nil,
            textRect.size,
            nil
        )

        var posY: Double

        switch properties.alignVertical {
        case .top:
            posY = textRect.maxY - frameSize.height
        case .center:
            posY = textRect.midY - frameSize.height / 2
        case .bottom:
            posY = textRect.minY
        }

        let framePath = CGPath(
            rect: CGRect(
                x: textRect.minX,
                y: posY,
                width: textRect.width,
                height: frameSize.height
            ),
            transform: nil
        )

        drawTextTwoPass(
            text: text,
            stringAttributes: stringAttributes,
            framePath: framePath,
            context: context
        )

        // let frameRef = CTFramesetterCreateFrame(
        //     frameSetter,
        //     CFRange(location: 0, length: 0),
        //     framePath,
        //     nil
        // )
        //
        // context.saveGState()
        // context.textMatrix = CGAffineTransform.identity
        //
        // CTFrameDraw(frameRef, context)
        //
        // context.restoreGState()
    }

    private func drawTextTwoPass(
        text: String,
        stringAttributes: [NSAttributedString.Key: Any],
        framePath: CGPath,
        context: CGContext
    ) {
        let noStrokeStringAttributes = stringAttributes.merging([.strokeWidth: 0]) {
            (_, new) in
            new
        }

        context.saveGState()
        context.textMatrix = CGAffineTransform.identity

        for stringAttributes in [stringAttributes, noStrokeStringAttributes] {
            let attributedString = NSAttributedString(
                string: text,
                attributes: stringAttributes as [NSAttributedString.Key: Any]
            )

            let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)

            let frameRef = CTFramesetterCreateFrame(
                frameSetter,
                CFRange(location: 0, length: 0),
                framePath,
                nil
            )

            CTFrameDraw(frameRef, context)
        }

        context.restoreGState()
    }

    private func calcFontSize(
        for string: String,
        attributes: [NSAttributedString.Key: Any],
        restraint: CGSize
    ) -> CGFloat {
        let sizeHash = [
            string,
            String(Int(restraint.height)),
            String(Int(restraint.width)),
        ]
        if let cachedSize = fontSizeCache[sizeHash] {
            return cachedSize
        }

        var fontSize = CGFloat(properties.fontMaxSize) + 1
        var attributedString: NSAttributedString
        var isOutOfBounds: Bool

        repeat {
            fontSize -= 1

            let font = NSFont(name: properties.fontName, size: fontSize)!

            let attributesTest = attributes.merging([.font: font]) { _, new in new }

            attributedString = NSAttributedString(
                string: string,
                attributes: attributesTest as [NSAttributedString.Key: Any]
            )

            isOutOfBounds =
                (attributedString.size().height > restraint.height
                    || attributedString.size().width > restraint.width)
        } while fontSize > 10 && isOutOfBounds

        fontSizeCache[sizeHash] = fontSize

        return fontSize
    }
}
