//
//  ThemePreview.swift
//
//  Created by cyan on 7/15/26.
//

import SwiftUI

/// Illustrated theme preview mirroring the website's color-pattern swatch.
///
/// With `showsBothSchemes` and at least two patterns, light and dark swatches are shown
/// side by side, otherwise a single swatch is drawn.
public struct ThemePreview: View {
  private let patterns: [String]
  private let showsBothSchemes: Bool

  public init(patterns: [String], showsBothSchemes: Bool) {
    self.patterns = patterns
    self.showsBothSchemes = showsBothSchemes
  }

  public var body: some View {
    HStack(spacing: 8) {
      if showsBothSchemes, patterns.count >= 2 {
        ColorPatternSwatch(pattern: patterns[0])
        ColorPatternSwatch(pattern: patterns[1])
      } else if let pattern = patterns.first {
        ColorPatternSwatch(pattern: pattern)
      }
    }
  }
}

// MARK: - ColorPatternSwatch

/// Draws a miniature editor illustration from one comma-separated palette (up to 6 fixed slots).
private struct ColorPatternSwatch: View {
  let pattern: String

  var body: some View {
    let palette = Palette(pattern: pattern)
    Canvas { context, size in
      let scale = size.width / Constants.viewBox.width
      context.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .color(palette.background)
      )

      for (index, row) in Constants.rows.enumerated() {
        let originY = (Constants.baseY + Double(index) * Constants.rowGap - Constants.barHeight * 0.5) * scale
        let height = Constants.barHeight * scale
        var originX = (Constants.padX + row.indent) * scale

        for token in row.tokens {
          let width = token.width * scale
          let rect = CGRect(x: originX, y: originY, width: width, height: height)
          context.fill(
            Path(roundedRect: rect, cornerRadius: height * 0.5),
            with: .color(palette.color(for: token.slot))
          )

          originX += (token.width + Constants.gap) * scale
        }
      }
    }
    .frame(
      width: Constants.frameWidth,
      height: Constants.frameWidth * Constants.viewBox.height / Constants.viewBox.width
    )
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(.quaternary, lineWidth: 1)
    }
  }
}

// MARK: - Private

private extension ColorPatternSwatch {
  /// Fixed slots, matching the registry's documented palette order.
  enum Slot: Int {
    case background, text, accent, keyword, string, comment
  }

  struct Token {
    let width: Double
    let slot: Slot
  }

  struct Row {
    let indent: Double
    let tokens: [Token]
  }

  struct Palette {
    private let colors: [Color]

    init(pattern: String) {
      colors = pattern
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
        .map { Color(hex: $0) }
    }

    var background: Color {
      colors.first ?? .white
    }

    /// Mirrors the website fallback chain: slot -> accent -> text -> background.
    func color(for slot: Slot) -> Color {
      color(at: slot.rawValue) ?? color(at: 2) ?? color(at: 1) ?? color(at: 0) ?? Color(white: 0.5)
    }

    private func color(at index: Int) -> Color? {
      colors.indices.contains(index) ? colors[index] : nil
    }
  }

  enum Constants {
    static let padX: Double = 24
    static let baseY: Double = 30
    static let rowGap: Double = 30
    static let gap: Double = 8
    static let barHeight: Double = 16
    static let frameWidth: Double = 120

    /// Row layout mirrors the website preview; each token is (width, slot).
    static let rows: [Row] = [
      Row(indent: 0, tokens: [Token(width: 64, slot: .comment), Token(width: 158, slot: .comment)]),
      Row(indent: 0, tokens: [Token(width: 168, slot: .accent)]),
      Row(indent: 0, tokens: [Token(width: 46, slot: .keyword), Token(width: 150, slot: .text)]),
      Row(indent: 22, tokens: [Token(width: 110, slot: .text), Token(width: 74, slot: .string)]),
      Row(indent: 22, tokens: [Token(width: 60, slot: .keyword), Token(width: 96, slot: .string)]),
    ]

    /// Computed with symmetric padding, matching the website's generated viewBox.
    static let viewBox: CGSize = {
      let maxRight = rows
        .map { row -> Double in
          let tokensWidth = row.tokens.reduce(0) { $0 + $1.width }
          let gaps = Double(max(0, row.tokens.count - 1)) * gap
          return padX + row.indent + tokensWidth + gaps
        }
        .max() ?? 0

      let topPad = baseY - barHeight * 0.5
      return CGSize(
        width: maxRight + padX,
        height: baseY + Double(rows.count - 1) * rowGap + barHeight * 0.5 + topPad
      )
    }()
  }
}

private extension Color {
  /// Parses a `#rgb` or `#rrggbb` hex string, falling back to gray when malformed.
  init(hex: String) {
    var value = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    if value.count == 3 {
      value = value.reduce(into: "") { $0 += String(repeating: $1, count: 2) }
    }

    guard value.count == 6, let code = UInt32(value, radix: 16) else {
      self = Color(white: 0.5)
      return
    }

    self = Color(
      red: Double((code >> 16) & 0xFF) / 255.0,
      green: Double((code >> 8) & 0xFF) / 255.0,
      blue: Double(code & 0xFF) / 255.0
    )
  }
}
