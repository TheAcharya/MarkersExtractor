import AppKit

extension NSColor {
    // https://stackoverflow.com/a/33397427
    convenience init(hexString: String, alpha: Double) {
        var int = UInt64()
        let r: UInt64
        let g: UInt64
        let b: UInt64

        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        Scanner(string: hex).scanHexInt64(&int)

        switch hex.count {
        case 3:  // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: alpha
        )
    }
}
