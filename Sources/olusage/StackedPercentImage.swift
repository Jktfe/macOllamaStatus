import AppKit

/// The whole menu bar item as ONE template image: the llama, an optional warning mark, and two small
/// stacked percentages (session on top, weekly below). SwiftUI's menu bar label only reliably shows a
/// single image, so everything is composited here, and macOS tints it like the other menu bar items.
enum StackedPercentImage {
    static func make(llama: NSImage, top: Int, bottom: Int, warn: Bool) -> NSImage {
        let font = NSFont.systemFont(ofSize: 9.5, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let lines = ["\(top)%", "\(bottom)%"] as [NSString]
        let textWidth = ceil(lines.map { $0.size(withAttributes: attrs).width }.max() ?? 0)
        let warnText = "⚠︎" as NSString
        let warnAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .semibold)]
        let warnWidth = warn ? ceil(warnText.size(withAttributes: warnAttrs).width) + 2 : 0
        let gap: CGFloat = 3
        let height: CGFloat = 18
        let width = llama.size.width + gap + warnWidth + textWidth
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            llama.draw(in: NSRect(x: 0, y: (height - llama.size.height) / 2, width: llama.size.width, height: llama.size.height))
            var x = llama.size.width + gap
            if warn {
                warnText.draw(at: NSPoint(x: x, y: (height - warnText.size(withAttributes: warnAttrs).height) / 2), withAttributes: warnAttrs)
                x += warnWidth
            }
            let lineHeight = height / 2
            for (i, line) in lines.enumerated() {
                let size = line.size(withAttributes: attrs)
                let y = height - lineHeight * CGFloat(i + 1) + (lineHeight - size.height) / 2
                line.draw(at: NSPoint(x: x + textWidth - size.width, y: y), withAttributes: attrs)   // right-aligned
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
