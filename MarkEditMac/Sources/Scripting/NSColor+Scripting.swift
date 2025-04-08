//
//  NSColor+Scripting.swift
//  MarkEditMac
//
//  Created by Stephen Kaplan on 4/4/25.
//

import AppKit

extension NSColor {
  static let RGBColorCoefficient: Double = 65535

  /// Unpacks incoming color descriptors into NSColor objects.
  @objc func scriptingRGBColor(with descriptor: NSAppleEventDescriptor) -> NSColor? {
    guard descriptor.descriptorType == typeRGBColor else {
      return nil
    }

    let data = descriptor.data
    let rgbColor = RGBColor()

    _ = data.withUnsafeBytes { ptr in
      if let rgbColor = ptr.baseAddress?.assumingMemoryBound(to: RGBColor.self).pointee {
        return rgbColor
      } else {
        return RGBColor()
      }
    }

    return NSColor(
      calibratedRed: Double(rgbColor.red) / Self.RGBColorCoefficient,
      green: Double(rgbColor.green) / Self.RGBColorCoefficient,
      blue: Double(rgbColor.blue) / Self.RGBColorCoefficient,
      alpha: 1.0
    )
  }

  /// Packs NSColor objects into event descriptors to send to AppleScript.
  @objc func scriptingRGBColorDescriptor() -> NSAppleEventDescriptor {
    guard let calibratedColor = usingColorSpace(.deviceRGB) else {
      return NSAppleEventDescriptor.null()
    }

    var rgbColor = RGBColor(
      red: UInt16(calibratedColor.redComponent * Self.RGBColorCoefficient),
      green: UInt16(calibratedColor.greenComponent * Self.RGBColorCoefficient),
      blue: UInt16(calibratedColor.blueComponent * Self.RGBColorCoefficient)
    )

    let descriptor = NSAppleEventDescriptor(
      descriptorType: typeRGBColor,
      bytes: &rgbColor,
      length: MemoryLayout<RGBColor>.size
    )

    return descriptor ?? NSAppleEventDescriptor.null()
  }
}
