//
//  EditorViewController+Statistics.swift
//  MarkEditMac
//
//  Created by cyan on 8/25/23.
//

import AppKit
import MarkEditKit
import Statistics

extension EditorViewController {
  func toggleStatisticsPopover(sourceView: NSView?) {
    if removePresentedPopovers(contentClass: StatisticsController.self) {
      return
    }

    guard let sourceView else {
      Logger.assertFail("Missing sourceView to proceed")
      return
    }

    Task {
      guard let content = try? await bridge.core.getReadableContent() else {
        return Logger.assertFail("Failed to get readable content from the editor")
      }

      let fileURL = content.selectionBased ? nil : document?.fileURL
      let titleLabel = Localized.Toolbar.statistics
      let mainTitle = content.selectionBased ? "\(titleLabel) (\(Localized.Settings.selection))" : titleLabel

      let statisticsController = StatisticsController(
        sourceText: content.sourceText,
        trimmedText: content.trimmedText,
        commentCount: content.commentCount,
        fileURL: fileURL,
        localizable: StatisticsLocalizable(
          mainTitle: mainTitle,
          characters: Localized.Statistics.characters,
          words: Localized.Statistics.words,
          sentences: Localized.Statistics.sentences,
          paragraphs: Localized.Statistics.paragraphs,
          comments: Localized.Statistics.comments,
          readTime: Localized.Statistics.readTime,
          fileSize: Localized.Statistics.fileSize
        )
      )

      present(
        statisticsController,
        asPopoverRelativeTo: sourceView.bounds,
        of: sourceView,
        preferredEdge: .maxY,
        behavior: .semitransient
      )
    }
  }
}
