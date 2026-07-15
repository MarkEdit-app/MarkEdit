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

  private let title: String

  @State private var visible = false

  public init(title: String) {
    self.title = title
  }

  public var body: some View {
    VStack(spacing: 10) {
      ProgressView()
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
