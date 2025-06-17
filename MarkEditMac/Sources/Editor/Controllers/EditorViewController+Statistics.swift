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
      guard let content = try? await bridge.core.getReadableContentPair() else {
        return Logger.assertFail("Failed to get readable content from the editor")
      }

      let statisticsController = StatisticsController(
        modernStyle: AppDesign.modernStyle,
        content: content,
        fileURL: document?.fileURL,
        localizable: StatisticsLocalizable(
          mainTitle: Localized.Toolbar.statistics,
          selection: Localized.Statistics.selection,
          document: Localized.Statistics.document,
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
