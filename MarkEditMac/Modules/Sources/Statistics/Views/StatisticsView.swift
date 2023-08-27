//
//  StatisticsView.swift
//
//  Created by cyan on 8/26/23.
//

import AppKit
import SwiftUI

struct StatisticsView: View {
  private let tokenizedResult: Tokenizer.Result
  private let fileURL: URL?
  private let localizable: StatisticsLocalizable

  init(
    tokenizedResult: Tokenizer.Result,
    fileURL: URL?,
    localizable: StatisticsLocalizable
  ) {
    self.tokenizedResult = tokenizedResult
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
          valueText: "\(tokenizedResult.characters)"
        )

        StatisticsCell(
          iconName: Icons.words,
          titleText: localizable.words,
          valueText: "\(tokenizedResult.words)"
        )

        StatisticsCell(
          iconName: Icons.sentences,
          titleText: localizable.sentences,
          valueText: "\(tokenizedResult.sentences)"
        )

        StatisticsCell(
          iconName: Icons.paragraphs,
          titleText: localizable.paragraphs,
          valueText: "\(tokenizedResult.paragraphs)"
        )

        if let readTime = ReadTime.compute(numberOfWords: tokenizedResult.words) {
          StatisticsCell(
            iconName: Icons.readTime,
            titleText: localizable.readTime,
            valueText: readTime
          )
        }

        if let fileSize = FileSize.readableSize(of: fileURL) {
          StatisticsCell(
            iconName: Icons.fileSize,
            titleText: localizable.fileSize,
            valueText: fileSize
          )
        }
      }
      .padding(.horizontal, 8)
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
