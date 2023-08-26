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
  private let tokenizedResult: Tokenizer.Result

  init(sourceText: String, fileURL: URL?, localizable: StatisticsLocalizable) {
    self.sourceText = sourceText
    self.fileURL = fileURL
    self.localizable = localizable
    self.tokenizedResult = Tokenizer.tokenize(text: sourceText)
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
          valueText: "\(sourceText.count)"
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

        if let fileSize = FileSize.readableSize(of: fileURL) {
          StatisticsCell(
            iconName: Icons.fileSize,
            titleText: localizable.fileSize,
            valueText: fileSize
          )
        }

        if let readTime = ReadTime.compute(numberOfWords: tokenizedResult.words) {
          StatisticsCell(
            iconName: Icons.readTime,
            titleText: localizable.readTime,
            valueText: readTime
          )
        }
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
