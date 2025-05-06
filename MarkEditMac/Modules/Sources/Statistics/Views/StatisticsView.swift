//
//  StatisticsView.swift
//
//  Created by cyan on 8/26/23.
//

import AppKit
import AppKitExtensions
import SwiftUI

struct StatisticsView: View {
  private let fullResult: StatisticsResult
  private let selectionResult: StatisticsResult?
  private let fileURL: URL?
  private let localizable: StatisticsLocalizable

  @State private var viewingMode: ViewingMode = .selection
  @State private var localMonitor: Any?

  init(
    fullResult: StatisticsResult,
    selectionResult: StatisticsResult?,
    fileURL: URL?,
    localizable: StatisticsLocalizable
  ) {
    self.fullResult = fullResult
    self.selectionResult = selectionResult
    self.fileURL = fileURL
    self.localizable = localizable
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack {
        if selectionResult != nil {
          Picker(localizable.mainTitle, selection: $viewingMode) {
            Text(localizable.selection).tag(ViewingMode.selection)
            Text(localizable.document).tag(ViewingMode.document)
          }
          .labelsHidden() // Hide the label while keeping the accessibility
          .pickerStyle(.segmented)
          .padding()
          .onAppear {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
              switch event.keyCode {
              case .kVK_LeftArrow:
                viewingMode = .selection
                return nil
              case .kVK_RightArrow:
                viewingMode = .document
                return nil
              default:
                return event
              }
            }
          }
          .onDisappear {
            if let localMonitor {
              NSEvent.removeMonitor(localMonitor)
              self.localMonitor = nil
            }
          }
        } else {
          Text(localizable.mainTitle)
            .fontWeight(.semibold)
        }
      }
      .frame(height: 36)

      Divider()

      ScrollView {
        VStack(spacing: 0) {
          StatisticsCell(
            iconName: Icons.characters,
            titleText: localizable.characters,
            valueText: "\(currentResult.characters)"
          )

          StatisticsCell(
            iconName: Icons.words,
            titleText: localizable.words,
            valueText: "\(currentResult.words)"
          )

          StatisticsCell(
            iconName: Icons.sentences,
            titleText: localizable.sentences,
            valueText: "\(currentResult.sentences)"
          )

          StatisticsCell(
            iconName: Icons.paragraphs,
            titleText: localizable.paragraphs,
            valueText: "\(currentResult.paragraphs)"
          )

          if currentResult.comments > 0 {
            StatisticsCell(
              iconName: Icons.comments,
              titleText: localizable.comments,
              valueText: "\(currentResult.comments)"
            )
          }

          if let readTime = ReadTime.estimated(of: currentResult.words) {
            StatisticsCell(
              iconName: Icons.readTime,
              titleText: localizable.readTime,
              valueText: readTime
            )
          }

          // The file size is shown only when we are viewing the full document
          if isViewingDocument, let fileSize = FileSize.readableSize(of: fileURL) {
            StatisticsCell(
              iconName: Icons.fileSize,
              titleText: localizable.fileSize,
              valueText: fileSize
            )
          }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
      }

      Spacer()
    }
  }
}

// MARK: - Private

private extension StatisticsView {
  enum ViewingMode: Int {
    case selection = 0
    case document = 1
  }

  enum Icons {
    static let characters = "textformat"
    static let words = "text.bubble"
    static let sentences = "textformat.abc.dottedunderline"
    static let paragraphs = "paragraphsign"
    static let comments = "eye.slash"
    static let readTime = "stopwatch"
    static let fileSize = "doc.text.below.ecg"
  }

  var isViewingDocument: Bool {
    // We are viewing full document if there's no selection, or we explicitly selected the document section
    selectionResult == nil || viewingMode == .document
  }

  var currentResult: StatisticsResult {
    if !isViewingDocument, let selectionResult {
      return selectionResult
    }

    return fullResult
  }
}
