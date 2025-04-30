//
//  StatisticsController.swift
//
//  Created by cyan on 8/25/23.
//

import AppKit
import SwiftUI
import MarkEditKit

/**
 UI to show statistics of text.
 */
public final class StatisticsController: NSViewController {
  private enum Constants {
    static let contentWidth: Double = 240
    static let contentHeight: Double = 288
  }

  private let content: ReadableContentPair
  private let fileURL: URL?
  private let localizable: StatisticsLocalizable
  private var contentView: NSView?

  public init(
    content: ReadableContentPair,
    fileURL: URL?,
    localizable: StatisticsLocalizable
  ) {
    self.content = content
    self.fileURL = fileURL
    self.localizable = localizable
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func loadView() {
    view = NSView(frame: CGRect(
      x: 0,
      y: 0,
      width: Constants.contentWidth,
      height: Constants.contentHeight
    ))
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    let spinner = NSProgressIndicator()
    spinner.style = .spinning
    spinner.startAnimation(nil)
    spinner.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(spinner)

    NSLayoutConstraint.activate([
      spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      spinner.widthAnchor.constraint(equalTo: spinner.heightAnchor),
      spinner.heightAnchor.constraint(equalToConstant: 24),
    ])

    // Natural language processing is time-consuming for large documents
    Task.detached(priority: .userInitiated) {
      let fullResult = self.content.fullText.tokenized
      let selectionResult = self.content.selection?.tokenized

      // Remove the spinner and show the result view on main thread
      DispatchQueue.main.async {
        spinner.stopAnimation(nil)
        spinner.removeFromSuperview()

        let contentView = NSHostingView(rootView: StatisticsView(
          fullResult: fullResult,
          selectionResult: selectionResult,
          fileURL: self.fileURL,
          localizable: self.localizable
        ))

        self.contentView = contentView
        self.view.addSubview(contentView)
        self.view.needsLayout = true
      }
    }
  }

  override public func viewDidAppear() {
    super.viewDidAppear()
    view.window?.makeFirstResponder(self)
  }

  override public func viewDidLayout() {
    super.viewDidLayout()
    contentView?.frame = view.bounds
  }
}

extension ReadableContentPair: @unchecked @retroactive Sendable {}

// MARK: - Private

private extension ReadableContent {
  var tokenized: Tokenizer.Result {
    Tokenizer.tokenize(
      sourceText: sourceText,
      trimmedText: trimmedText,
      commentCount: commentCount
    )
  }
}
