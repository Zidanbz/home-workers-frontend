import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: "assets/logo_howe_branding.png")
let splashMarkOutputURL = URL(
  fileURLWithPath: "assets/logo_howe_splash_mark.png"
)
let android12CompositeOutputURL = URL(
  fileURLWithPath: "assets/logo_howe_splash_android12_composite.png"
)
let transparentSplashOutputURL = URL(
  fileURLWithPath: "assets/logo_howe_splash_transparent.png"
)
let canvasSize = NSSize(width: 800, height: 320)

guard let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: Int(canvasSize.width),
  pixelsHigh: Int(canvasSize.height),
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fatalError("Gagal membuat bitmap splash branding.")
}

bitmap.size = canvasSize
guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
  fatalError("Gagal membuat graphics context splash branding.")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor.clear.setFill()
NSRect(origin: .zero, size: canvasSize).fill()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attributes: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: 72, weight: .bold),
  .foregroundColor: NSColor.white,
  .kern: 5.0,
  .paragraphStyle: paragraph,
]
let branding = NSAttributedString(string: "HOME WORKERS", attributes: attributes)
let textBounds = branding.boundingRect(
  with: NSSize(width: canvasSize.width, height: canvasSize.height),
  options: [.usesLineFragmentOrigin, .usesFontLeading]
)
let drawingRect = NSRect(
  x: 0,
  y: (canvasSize.height - textBounds.height) / 2,
  width: canvasSize.width,
  height: textBounds.height
)
branding.draw(with: drawingRect, options: [.usesLineFragmentOrigin, .usesFontLeading])

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
  fatalError("Gagal melakukan encode PNG splash branding.")
}
try png.write(to: outputURL, options: .atomic)
print("Generated \(outputURL.path) (800x320)")

guard let sourceImage = NSImage(
  contentsOfFile: "assets/logo_howe_splash_android12.png"
) else {
  fatalError("Gagal membaca logo sumber splash Android 12.")
}

let markCanvasSize = NSSize(width: 512, height: 512)
guard let markBitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: Int(markCanvasSize.width),
  pixelsHigh: Int(markCanvasSize.height),
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fatalError("Gagal membuat bitmap logo splash.")
}

markBitmap.size = markCanvasSize
guard let markContext = NSGraphicsContext(bitmapImageRep: markBitmap) else {
  fatalError("Gagal membuat graphics context logo splash.")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = markContext
NSColor.clear.setFill()
NSRect(origin: .zero, size: markCanvasSize).fill()

// Ambil hanya simbol rumah + Worker dari kanvas Android 12. Area transparan
// yang tersisa menjaga simbol tidak terlalu rapat saat dirender responsif.
sourceImage.draw(
  in: NSRect(origin: .zero, size: markCanvasSize),
  from: NSRect(x: 224, y: 224, width: 512, height: 512),
  operation: .copy,
  fraction: 1
)

markContext.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let markPng = markBitmap.representation(using: .png, properties: [:]) else {
  fatalError("Gagal melakukan encode PNG logo splash.")
}
try markPng.write(to: splashMarkOutputURL, options: .atomic)
print("Generated \(splashMarkOutputURL.path) (512x512)")

guard let markImage = NSImage(data: markPng) else {
  fatalError("Gagal membaca hasil logo splash.")
}

let android12CanvasSize = NSSize(width: 960, height: 960)
guard let android12Bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: Int(android12CanvasSize.width),
  pixelsHigh: Int(android12CanvasSize.height),
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fatalError("Gagal membuat bitmap splash Android 12.")
}

android12Bitmap.size = android12CanvasSize
guard let android12Context = NSGraphicsContext(bitmapImageRep: android12Bitmap) else {
  fatalError("Gagal membuat graphics context splash Android 12.")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = android12Context
NSColor.clear.setFill()
NSRect(origin: .zero, size: android12CanvasSize).fill()

// Seluruh komposisi dijaga di dalam safe circle splash Android 12 agar nama
// brand tidak terpotong oleh mask ikon sistem.
markImage.draw(
  in: NSRect(x: 220, y: 380, width: 520, height: 520),
  from: NSRect(origin: .zero, size: markCanvasSize),
  operation: .sourceOver,
  fraction: 1
)

let android12Paragraph = NSMutableParagraphStyle()
android12Paragraph.alignment = .center
let android12SafeTextInset: CGFloat = 190
let android12SafeTextWidth =
  android12CanvasSize.width - (android12SafeTextInset * 2)
let android12TextAttributes: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: 64, weight: .bold),
  .foregroundColor: NSColor.white,
  .kern: 2.0,
  .paragraphStyle: android12Paragraph,
]
let android12Branding = NSAttributedString(
  string: "HOME WORKERS",
  attributes: android12TextAttributes
)
let android12TextBounds = android12Branding.boundingRect(
  with: NSSize(width: android12SafeTextWidth, height: 140),
  options: [.usesLineFragmentOrigin, .usesFontLeading]
)
android12Branding.draw(
  with: NSRect(
    x: android12SafeTextInset,
    y: 345,
    width: android12SafeTextWidth,
    height: android12TextBounds.height
  ),
  options: [.usesLineFragmentOrigin, .usesFontLeading]
)

android12Context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard
  let android12Png = android12Bitmap.representation(
    using: .png,
    properties: [:]
  )
else {
  fatalError("Gagal melakukan encode PNG splash Android 12.")
}
try android12Png.write(to: android12CompositeOutputURL, options: .atomic)
print("Generated \(android12CompositeOutputURL.path) (960x960)")

guard let transparentBitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: 960,
  pixelsHigh: 960,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fatalError("Gagal membuat bitmap splash transparan.")
}

transparentBitmap.size = NSSize(width: 960, height: 960)
guard let transparentContext = NSGraphicsContext(bitmapImageRep: transparentBitmap) else {
  fatalError("Gagal membuat graphics context splash transparan.")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = transparentContext
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: 960, height: 960).fill()
transparentContext.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard
  let transparentPng = transparentBitmap.representation(
    using: .png,
    properties: [:]
  )
else {
  fatalError("Gagal melakukan encode PNG splash transparan.")
}
try transparentPng.write(to: transparentSplashOutputURL, options: .atomic)
print("Generated \(transparentSplashOutputURL.path) (960x960 transparent)")
