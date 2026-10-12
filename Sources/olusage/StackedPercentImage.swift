import AppKit

/// Two small stacked percentages (session on top, weekly below) as a template image, so macOS tints
/// them like the other menu bar items.
enum StackedPercentImage {
    static func make(top: Int, bottom: Int) -> NSImage {
        let font = NSFont.systemFont(ofSize: 9.5, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let lines = ["\(top)%", "\(bottom)%"] as [NSString]
        let width = ceil(lines.map { $0.size(withAttributes: attrs).width }.max() ?? 0)
        let height: CGFloat = 18
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            let lineHeight = height / 2
            for (i, line) in lines.enumerated() {
                let size = line.size(withAttributes: attrs)
                let y = height - lineHeight * CGFloat(i + 1) + (lineHeight - size.height) / 2
                line.draw(at: NSPoint(x: width - size.width, y: y), withAttributes: attrs)   // right-aligned
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
