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
    if let presentedViewControllers {
      var didHide = false
      for presented in presentedViewControllers where presented is StatisticsController {
        dismiss(presented)
        didHide = true
      }
      if didHide {
        return
      }
    }

    guard let sourceView else {
      Logger.assertFail("Missing sourceView to proceed")
      return
    }

    Task {
      // Extract the source to show the statistics view,
      // use the selected text if the selection is not empty.
      let (sourceText, fileURL, mainTitle) = await {
        let selectedText = (try? await bridge.selection.getText()) ?? ""
        let mainTitle = Localized.Toolbar.statistics

        return (
          selectedText.isEmpty ? (await editorText ?? "") : selectedText,
          selectedText.isEmpty ? document?.fileURL : nil,
          selectedText.isEmpty ? mainTitle : "\(mainTitle) (\(Localized.Settings.selection))"
        )
      }()

      let statisticsController = StatisticsController(
        sourceText: sourceText,
        fileURL: fileURL,
        localizable: StatisticsLocalizable(
          mainTitle: mainTitle,
          characters: Localized.Statistics.characters,
          words: Localized.Statistics.words,
          sentences: Localized.Statistics.sentences,
          paragraphs: Localized.Statistics.paragraphs,
          readTime: Localized.Statistics.readTime,
          fileSize: Localized.Statistics.fileSize
        )
      )
      present(statisticsController, asPopoverRelativeTo: sourceView.bounds, of: sourceView, preferredEdge: .maxY, behavior: .transient)
    }
  }
}
