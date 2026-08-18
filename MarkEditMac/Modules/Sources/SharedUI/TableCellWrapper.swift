//
//  TableCellWrapper.swift
//
//  Created by cyan on 7/15/26.
//

import AppKit
import SwiftUI

/// Table cell that hosts an arbitrary SwiftUI view, filling the full cell width.
public final class TableCellWrapper: NSTableCellView {
  @MainActor
  public final class Measurer {
    public init() {}

    public func size(for rootView: some View, width: Double) -> CGSize {
      controller.rootView = AnyView(rootView)
      return controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    public func fittingHeight(for rootView: some View, width: Double) -> Double {
      let contentSize = size(for: rootView, width: width)
      return ceil(contentSize.height + verticalInset * 2)
    }

    private let controller = NSHostingController(rootView: AnyView(EmptyView()))
  }

  private static let verticalInset: Double = 2
  private let hostingView = NSHostingView(rootView: AnyView(EmptyView()))

  public init() {
    super.init(frame: .zero)
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(hostingView)

    NSLayoutConstraint.activate([
      hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
      hostingView.topAnchor.constraint(equalTo: topAnchor, constant: Self.verticalInset),
      hostingView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.verticalInset),
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
