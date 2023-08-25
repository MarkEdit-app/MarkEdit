//
//  StatisticsViewController.swift
//
//  Created by cyan on 8/25/23.
//

import AppKit

/**
 UI to show statistics of text.
 */
public final class StatisticsViewController: NSViewController {
  private enum Constants {
    static let contentWidth: Double = 240
    static let contentHeight: Double = 300
  }

  private let sourceText: String
  private let localizable: StatisticsLocalizable

  public init(sourceText: String, localizable: StatisticsLocalizable) {
    self.sourceText = sourceText
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
}
