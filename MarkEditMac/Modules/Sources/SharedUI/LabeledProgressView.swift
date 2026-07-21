//
//  LabeledProgressView.swift
//
//  Created by cyan on 7/15/26.
//

import SwiftUI

/// A titled progress indicator that fades itself in on appear (honoring reduce motion).
public struct LabeledProgressView: View {
  @Environment(\.accessibilityReduceMotion)
  private var reduceMotion
  @State private var visible = false

  private let title: String
  private let progress: Double?

  public init(title: String, progress: Double? = nil) {
    self.title = title
    self.progress = progress
  }

  public var body: some View {
    VStack(spacing: 10) {
      if let progress {
        RingProgressView(value: progress)
          .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: progress)
      } else {
        ProgressView()
      }

      Text(title)
        .foregroundStyle(.secondary)
    }
    .padding()
    .opacity(visible ? 1 : 0)
    .onAppear {
      withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
        visible = true
      }
    }
  }
}

// MARK: - Private

@Animatable
private struct RingProgressView: View {
  var value: Double

  var body: some View {
    ProgressView(value: max(0, min(1, value)))
      .progressViewStyle(.circular)
      .controlSize(.large)
  }
}
