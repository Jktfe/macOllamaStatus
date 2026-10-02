import AppKit

/// A small monochrome llama for the menu bar. Drawn from the 🦙 glyph's silhouette and marked as a
/// template image, so macOS tints it like every other menu bar icon (white in dark mode, black in light).
enum MenuBarIcon {
    static let llama: NSImage = {
        let height: CGFloat = 16
        let glyph = "🦙" as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: height)]
        let glyphSize = glyph.size(withAttributes: attrs)
        let image = NSImage(size: NSSize(width: glyphSize.width, height: height), flipped: false) { rect in
            glyph.draw(at: NSPoint(x: 0, y: (height - glyphSize.height) / 2), withAttributes: attrs)
            // Keep only the glyph's shape: replace its colours with solid black.
            NSColor.black.setFill()
            rect.fill(using: .sourceIn)
            return true
        }
        image.isTemplate = true
        return image
    }()
}
