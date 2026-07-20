//
//  TableCellWrapper.swift
//
//  Created by cyan on 7/15/26.
//

import AppKit
import SwiftUI

/// Table cell that hosts an arbitrary SwiftUI view, filling the full cell width.
public final class TableCellWrapper: NSTableCellView {
  private let hostingView = NSHostingView(rootView: AnyView(EmptyView()))

  public init() {
    super.init(frame: .zero)
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(hostingView)

    NSLayoutConstraint.activate([
      hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
      hostingView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
      hostingView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func configure(_ rootView: some View) {
    hostingView.rootView = AnyView(rootView)
  }
}
