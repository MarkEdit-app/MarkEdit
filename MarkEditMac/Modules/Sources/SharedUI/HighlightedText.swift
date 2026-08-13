//
//  HighlightedText.swift
//
//  Created by cyan on 8/1/26.
//

import SwiftUI

/// Text with search-style highlighting, the entire string is highlighted once when revealed.
public struct HighlightedText: View {
  private let text: String
  private let query: String
  private let isRevealed: Bool

  @State private var showsOverlay = false
  @State private var revealOpacity: Double = 0
  @State private var revealTask: Task<Void, Never>?

  public init(_ text: String, query: String, isRevealed: Bool) {
    self.text = text
    self.query = query
    self.isRevealed = isRevealed
  }

  public var body: some View {
    Text(text, highlighting: query)
      // Fully highlighted copy on top, attributes are not animatable but opacity is
      .overlay {
        if showsOverlay {
          Text(text, highlighting: text)
            .opacity(revealOpacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
      }
      // The content can appear either before or after being revealed
      .onAppear { revealIfNeeded() }
      .onDisappear { cancelReveal() }
      .onChange(of: isRevealed) { revealIfNeeded() }
  }
}

// MARK: - Private

private extension HighlightedText {
  enum Constants {
    static let holdDuration: Double = 1.0
    static let fadeInDuration: Double = 0.5
    static let fadeOutDuration: Double = 0.5
  }

  func revealIfNeeded() {
    guard isRevealed else {
      return
    }

    cancelReveal()
    showsOverlay = true

    revealTask = Task { @MainActor in
      await Task.yield()
      guard !Task.isCancelled else {
        return
      }

      withAnimation(.easeInOut(duration: Constants.fadeInDuration)) {
        revealOpacity = 1
      }

      try? await Task.sleep(for: .seconds(Constants.fadeInDuration + Constants.holdDuration))
      guard !Task.isCancelled else {
        return
      }

      withAnimation(.easeInOut(duration: Constants.fadeOutDuration)) {
        revealOpacity = 0
      }

      try? await Task.sleep(for: .seconds(Constants.fadeOutDuration))
      guard !Task.isCancelled else {
        return
      }

      showsOverlay = false
    }
  }

  func cancelReveal() {
    revealTask?.cancel()
    revealTask = nil
    revealOpacity = 0
    showsOverlay = false
  }
}
