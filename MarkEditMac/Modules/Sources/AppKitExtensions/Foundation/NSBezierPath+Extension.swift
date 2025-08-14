//
//  NSBezierPath+Extension.swift
//
//  Created by cyan on 8/13/25.
//

import AppKit

@MainActor
public extension NSBezierPath {
  struct Corners: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    @MainActor public static let topLeft = Self(rawValue: 1 << 0)
    @MainActor public static let topRight = Self(rawValue: 1 << 1)
    @MainActor public static let bottomRight = Self(rawValue: 1 << 2)
    @MainActor public static let bottomLeft = Self(rawValue: 1 << 3)
    @MainActor public static let left: Self = [.topLeft, .bottomLeft]
    @MainActor public static let right: Self = [.topRight, .bottomRight]
    @MainActor public static let all: Self = [.left, .right]
  }

  /**
   Creates a bezier path, allowing specific corners to be rounded.
   */
  convenience init(roundedRect rect: CGRect, radius: Double, corners: Corners = .all) {
    guard corners != .all else {
      self.init(roundedRect: rect, xRadius: radius, yRadius: radius)
      return
    }

    self.init()
    let radius = min(max(0, radius), min(rect.width, rect.height) * 0.5)
    let offset = radius * (1 - 0.55228475)

    // Start from top left, clockwise
    move(to: CGPoint(
      x: rect.minX + (corners.contains(.topLeft) ? radius : 0),
      y: rect.minY
    ))

    // Line and curve to top right
    line(to: CGPoint(x: rect.maxX - (corners.contains(.topRight) ? radius : 0), y: rect.minY))
    if corners.contains(.topRight) {
      curve(
        to: CGPoint(x: rect.maxX, y: rect.minY + radius),
        controlPoint1: CGPoint(x: rect.maxX - offset, y: rect.minY),
        controlPoint2: CGPoint(x: rect.maxX, y: rect.minY + offset)
      )
    }

    // Line and curve to bottom right
    line(to: CGPoint(x: rect.maxX, y: rect.maxY - (corners.contains(.bottomRight) ? radius : 0)))
    if corners.contains(.bottomRight) {
      curve(
        to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
        controlPoint1: CGPoint(x: rect.maxX, y: rect.maxY - offset),
        controlPoint2: CGPoint(x: rect.maxX - offset, y: rect.maxY)
      )
    }

    // Line and curve to bottom left
    line(to: CGPoint(x: rect.minX + (corners.contains(.bottomLeft) ? radius : 0), y: rect.maxY))
    if corners.contains(.bottomLeft) {
      curve(
        to: CGPoint(x: rect.minX, y: rect.maxY - radius),
        controlPoint1: CGPoint(x: rect.minX + offset, y: rect.maxY),
        controlPoint2: CGPoint(x: rect.minX, y: rect.maxY - offset)
      )
    }

    // Back to top left and close the path
    line(to: CGPoint(x: rect.minX, y: rect.minY + (corners.contains(.topLeft) ? radius : 0)))
    if corners.contains(.topLeft) {
      curve(
        to: CGPoint(x: rect.minX + radius, y: rect.minY),
        controlPoint1: CGPoint(x: rect.minX, y: rect.minY + offset),
        controlPoint2: CGPoint(x: rect.minX + offset, y: rect.minY)
      )
    }

    close()
  }
}
