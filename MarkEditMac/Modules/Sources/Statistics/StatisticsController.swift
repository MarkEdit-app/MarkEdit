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

  private let contentView: NSView

  public init(sourceText: String, fileURL: URL?, localizable: StatisticsLocalizable) {
    self.contentView = NSHostingView(rootView: StatisticsView(
      sourceText: sourceText,
      fileURL: fileURL,
      localizable: localizable
    ))

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

    view.addSubview(contentView)
  }

  override public func viewDidLayout() {
    super.viewDidLayout()
    contentView.frame = view.bounds
  }
}
