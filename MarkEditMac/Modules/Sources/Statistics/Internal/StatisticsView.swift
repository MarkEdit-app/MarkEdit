//
//  StatisticsView.swift
//
//  Created by cyan on 8/26/23.
//

import AppKit
import SwiftUI

struct StatisticsView: View {
  private let sourceText: String
  private let fileURL: URL?
  private let localizable: StatisticsLocalizable

  init(sourceText: String, fileURL: URL?, localizable: StatisticsLocalizable) {
    self.sourceText = sourceText
    self.fileURL = fileURL
    self.localizable = localizable
  }

  var body: some View {
    VStack(spacing: 0) {
      Text(localizable.mainTitle)
        .fontWeight(.semibold)
        .frame(height: 36)

      Divider()

      VStack(spacing: 0) {
        StatisticsCell(
          iconName: Icons.characters,
          titleText: localizable.characters,
          valueText: "2302"
        )

        StatisticsCell(
          iconName: Icons.words,
          titleText: localizable.words,
          valueText: "532"
        )

        StatisticsCell(
          iconName: Icons.sentences,
          titleText: localizable.sentences,
          valueText: "82"
        )

        StatisticsCell(
          iconName: Icons.paragraphs,
          titleText: localizable.paragraphs,
          valueText: "25"
        )

        StatisticsCell(
          iconName: Icons.fileSize,
          titleText: localizable.fileSize,
          valueText: "10 KB"
        )

        StatisticsCell(
          iconName: Icons.readTime,
          titleText: localizable.readTime,
          valueText: "2m"
        )
      }
      .padding(.horizontal, 10)
      .frame(maxWidth: .infinity)

      Spacer()
    }
  }
}

// MARK: - Private

private enum Icons {
  static let characters = "textformat"
  static let words = "text.bubble"
  static let sentences = "textformat.abc.dottedunderline"
  static let paragraphs = "paragraphsign"
  static let fileSize = "doc.text.below.ecg"
  static let readTime = "stopwatch"
}
