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
      .onAppear { fadeOutIfNeeded() }
      .onChange(of: isRevealed) { fadeOutIfNeeded() }
  }
}

// MARK: - Private

private extension HighlightedText {
  enum Constants {
    static let holdDuration: Double = 1.5
    static let fadeOutDuration: Double = 0.5
  }

  func fadeOutIfNeeded() {
    guard isRevealed else {
      return
    }

    showsOverlay = true
    revealOpacity = 1

    withAnimation(
      .easeInOut(duration: Constants.fadeOutDuration).delay(Constants.holdDuration)
    ) {
      revealOpacity = 0
    } completion: {
      showsOverlay = false
    }
  }
}
