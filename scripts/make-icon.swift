// Renders the app icon (llama on a rounded square) to a PNG: swift scripts/make-icon.swift out.png
import AppKit
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let rect = NSRect(x: 0, y: 0, width: size, height: size).insetBy(dx: 100, dy: 100)
NSGradient(colors: [NSColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1), NSColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1)])!
    .draw(in: NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185), angle: -90)
let llama = "🦙" as NSString
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 560)]
let s = llama.size(withAttributes: attrs)
llama.draw(at: NSPoint(x: (size - s.width) / 2, y: (size - s.height) / 2), withAttributes: attrs)
image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
