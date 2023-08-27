//
//  StatisticsController.swift
//
//  Created by cyan on 8/25/23.
//

import AppKit
import SwiftUI

/**
 UI to show statistics of text.
 */
public final class StatisticsController: NSViewController {
  private enum Constants {
    static let contentWidth: Double = 240
    static let contentHeight: Double = 288
  }

  private let sourceText: String
  private let fileURL: URL?
  private let localizable: StatisticsLocalizable
  private var contentView: NSView?

  public init(sourceText: String, fileURL: URL?, localizable: StatisticsLocalizable) {
    self.sourceText = sourceText
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
    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.startAnimation(nil)
    view.addSubview(spinner)

    NSLayoutConstraint.activate([
      spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])

    DispatchQueue.global(qos: .userInitiated).async {
      // Natural language processing is time-consuming for large documents
      let tokenizedResult = Tokenizer.tokenize(text: self.sourceText)
      // Render the result view and remove the spinner on main thread
      DispatchQueue.main.async {
        let contentView = NSHostingView(rootView: StatisticsView(
          tokenizedResult: tokenizedResult,
          fileURL: self.fileURL,
          localizable: self.localizable
        ))

        spinner.stopAnimation(nil)
        spinner.removeFromSuperview()

        self.contentView = contentView
        self.view.addSubview(contentView)
        self.view.needsLayout = true
      }
    }
  }

  override public func viewDidLayout() {
    super.viewDidLayout()
    contentView?.frame = view.bounds
  }
}
