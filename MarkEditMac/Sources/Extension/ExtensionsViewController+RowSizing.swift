//
//  ExtensionsViewController+RowSizing.swift
//  MarkEditMac
//
//  Created by cyan on 8/18/26.
//

import AppKit
import SharedUI
import SwiftUI

extension ExtensionsViewController {
  struct RowMetrics {
    let item: ExtensionsModel.Item
    let mode: ExtensionsModel.Mode
    let baseHeight: Double
    let trailingControlWidth: Double
  }

  struct TrailingControlKey: Hashable {
    let isLocalList: Bool
    let isInstalled: Bool
    let hasUpdate: Bool
  }

  enum RowSizing {
    static let contentSpacing: Double = 10
  }

  var rowContentWidth: Double {
    guard tableView.bounds.width > 0, let column = tableView.tableColumns.first else {
      return view.bounds.width
    }

    return column.width
  }

  func rowContent(
    for item: ExtensionsModel.Item,
    rowHeightChanged: @escaping () -> Void = {}
  ) -> ExtensionsRowView {
    ExtensionsRowView(
      model: model,
      item: item,
      listInteraction: listInteraction,
      rowMargin: rowMargin,
      rowHeightChanged: rowHeightChanged
    )
  }

  func updateRowLayout() {
    scrollView.layoutSubtreeIfNeeded()
    let width = rowContentWidth
    guard width != rowLayoutWidth else {
      return
    }

    rowLayoutWidth = width
    reloadRows(IndexSet(displayedItems.indices.filter { index in
      needResizeRow(at: index, for: displayedItems[index])
    }))
  }

  func reloadRows(_ rows: IndexSet) {
    guard !rows.isEmpty else {
      return
    }

    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0
      context.allowsImplicitAnimation = false
      tableView.noteHeightOfRows(withIndexesChanged: rows)
      tableView.reloadData(forRowIndexes: rows, columnIndexes: IndexSet(integer: 0))
      tableView.layoutSubtreeIfNeeded()
    }
  }

  func fittingHeight(for item: ExtensionsModel.Item) -> Double {
    let rowView = rowContent(for: item)
    if let metrics = rowMetrics[item.id], metrics.item == item, metrics.mode == model.mode {
      return metrics.baseHeight + subtitleExtraHeight(for: rowView, controlWidth: metrics.trailingControlWidth)
    }

    let controlKey = TrailingControlKey(
      isLocalList: model.mode.isLocalList,
      isInstalled: item.isInstalled,
      hasUpdate: item.updateVersion != nil
    )

    let controlWidth = trailingControlWidths[controlKey] ?? {
      let width = rowMeasurer.size(for: rowView.sizingTrailingControl, width: .greatestFiniteMagnitude).width
      trailingControlWidths[controlKey] = width
      return width
    }()

    let fullHeight = rowMeasurer.fittingHeight(for: rowView, width: rowContentWidth)
    let subtitleExtraHeight = subtitleExtraHeight(for: rowView, controlWidth: controlWidth)
    rowMetrics[item.id] = RowMetrics(
      item: item,
      mode: model.mode,
      baseHeight: fullHeight - subtitleExtraHeight,
      trailingControlWidth: controlWidth
    )

    return fullHeight
  }

  func subtitleExtraHeight(for rowView: ExtensionsRowView, controlWidth: Double) -> Double {
    guard let text = rowView.sizingSubtitleText else {
      return 0
    }

    let availableWidth = max(
      0,
      rowContentWidth - rowMargin * 2 - RowSizing.contentSpacing - controlWidth
    )

    let subtitle = rowView.sizingSubtitle(text)
    let singleLineHeight = rowMeasurer.size(for: subtitle, width: .greatestFiniteMagnitude).height
    let fittedHeight = rowMeasurer.size(for: subtitle, width: availableWidth).height
    return ceil(max(0, fittedHeight - singleLineHeight))
  }

  func needResizeRow(at index: Int, for item: ExtensionsModel.Item) -> Bool {
    let fittingHeight = fittingHeight(for: item)
    let rowHeight = tableView.rect(ofRow: index).height
    let cellHeight = tableView.view(atColumn: 0, row: index, makeIfNecessary: false)?.frame.height
    return rowHeight != fittingHeight || cellHeight.map { $0 != fittingHeight } == true
  }
}
