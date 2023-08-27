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
    guard presentedPopover == nil else {
      presentedPopover?.close()
      return
    }

    guard let sourceView else {
      Logger.assertFail("Missing sourceView to proceed")
      return
    }

    Task {
      let (sourceText, fileURL, mainTitle) = await {
        let selectedText = (try? await bridge.selection.getText()) ?? ""
        let mainTitle = Localized.Toolbar.statistics

        return (
          selectedText.isEmpty ? (await editorText ?? "") : selectedText,
          selectedText.isEmpty ? document?.fileURL : nil,
          selectedText.isEmpty ? mainTitle : "\(mainTitle) (\(Localized.Settings.selection))"
        )
      }()

      let popover = NSPopover()
      popover.behavior = .transient
      popover.contentViewController = StatisticsController(
        sourceText: sourceText,
        fileURL: fileURL,
        localizable: StatisticsLocalizable(
          mainTitle: mainTitle,
          characters: Localized.Statistics.characters,
          words: Localized.Statistics.words,
          sentences: Localized.Statistics.sentences,
          paragraphs: Localized.Statistics.paragraphs,
          fileSize: Localized.Statistics.fileSize,
          readTime: Localized.Statistics.readTime
        )
      )

      presentedPopover = popover
      popover.show(relativeTo: sourceView.bounds, of: sourceView, preferredEdge: .maxY)
    }
  }
}
