//
//  SpinningRing.swift
//
//  Created by cyan on 7/15/26.
//

import SwiftUI

/// App Store style progress indicator: a partial ring that keeps spinning.
public struct SpinningRing: View {
  private let size: Double
  private let lineWidth: Double

  @State private var spinning = false

  public init(size: Double = 20, lineWidth: Double = 2) {
    self.size = size
    self.lineWidth = lineWidth
  }

  public var body: some View {
    Circle()
      .trim(from: 0, to: 0.75)
      .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
      .frame(width: size, height: size)
      .rotationEffect(.degrees(spinning ? 360 : 0))
      .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: spinning)
      .onAppear { spinning = true }
  }
}
