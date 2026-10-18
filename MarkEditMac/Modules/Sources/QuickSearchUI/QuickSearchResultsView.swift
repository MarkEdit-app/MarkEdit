//
//  QuickSearchResultsView.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit
import AppKitExtensions

final class QuickSearchResultsView: NSView {
  var isEnabled = true

  var preferredHeight: Double {
    let rowsHeight = min(Double(items.count) * 52 + 16, 7.5 * 52 + 8)
    return (items.isEmpty && messageField.isHidden ? 0 : rowsHeight) + (messageField.isHidden ? 0 : 48)
  }

  private let tableView = ResultsTableView()
  private let scrollView = NSScrollView()
  private let messageField = NSTextField(wrappingLabelWithString: "")
  private let separator = NSBox()
  private let onActivate: (String) -> Void
  private var items: [QuickSearchItem] = []

  init(onActivate: @escaping (String) -> Void) {
    self.onActivate = onActivate
    super.init(frame: .zero)
    isHidden = true

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("result"))
    tableView.addTableColumn(column)
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.style = .plain
    tableView.rowHeight = 52
    tableView.intercellSpacing = .zero
    tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    tableView.delegate = self
    tableView.dataSource = self
    tableView.target = self
    tableView.action = #selector(activateClickedRow)
    tableView.autoresizingMask = [.width]

    scrollView.documentView = tableView
    scrollView.automaticallyAdjustsContentInsets = false

    // Counteract content padding for the scrollbar, but keep the rows inset
    scrollView.scrollerInsets = NSEdgeInsets(
      top: 0,
      left: 0,
      bottom: 0,
      right: -8
    )

    scrollView.drawsBackground = false
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true
    addSubview(scrollView)

    messageField.font = .systemFont(ofSize: 12)
    messageField.textColor = .secondaryLabelColor
    messageField.maximumNumberOfLines = 3
    messageField.isHidden = true
    addSubview(messageField)

    separator.boxType = .separator
    addSubview(separator)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()

    let messageHeight: Double = messageField.isHidden ? 0 : 48
    messageField.frame = CGRect(x: 12, y: 8, width: max(0, bounds.width - 24), height: messageHeight)

    let scrollHeight = max(0, bounds.height - messageHeight)
    let padding = min(8, scrollHeight * 0.5)
    let insets = NSEdgeInsets(top: padding, left: 8, bottom: padding, right: 8)

    // Reduce padding before shrinking so it never exceeds the scroll viewport
    if scrollHeight < scrollView.bounds.height {
      scrollView.contentInsets = insets
    }

    scrollView.frame = CGRect(
      x: 0,
      y: messageHeight,
      width: bounds.width,
      height: scrollHeight
    )

    scrollView.contentInsets = insets
    tableView.sizeLastColumnToFit()
    separator.frame = CGRect(x: 12, y: max(0, bounds.height - 1), width: max(0, bounds.width - 24), height: 1)
  }

  func update(_ items: [QuickSearchItem], message: String?, preserveSelection: Bool) {
    let selectedID: String? = if self.items.indices.contains(tableView.selectedRow) {
      self.items[tableView.selectedRow].id
    } else {
      nil
    }

    let itemsChanged = self.items != items
    self.items = items
    messageField.stringValue = message ?? ""
    messageField.toolTip = message
    messageField.isHidden = message == nil
    isHidden = items.isEmpty && message == nil

    if itemsChanged {
      tableView.reloadData()
    }

    if itemsChanged || !preserveSelection {
      let index = preserveSelection ? items.firstIndex { $0.id == selectedID } : nil

      if !items.isEmpty {
        tableView.selectRowIndexes(IndexSet(integer: index ?? 0), byExtendingSelection: false)
        tableView.scrollRowToVisible(index ?? 0)
      } else {
        tableView.deselectAll(nil)
      }
    }

    needsLayout = true
  }

  func moveSelection(by offset: Int) {
    guard isEnabled, !items.isEmpty else {
      return
    }

    let index = min(max(tableView.selectedRow + offset, 0), items.count - 1)
    tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
    tableView.scrollRowToVisible(index)
  }

  func activateSelection() {
    guard isEnabled else {
      return
    }

    guard items.indices.contains(tableView.selectedRow) else {
      NSSound.beep()
      return
    }

    onActivate(items[tableView.selectedRow].id)
  }

  @objc private func activateClickedRow() {
    guard tableView.clickedRow >= 0 else {
      return
    }

    activateSelection()
  }
}

extension QuickSearchResultsView: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    items.count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let identifier = NSUserInterfaceItemIdentifier("resultCell")
    let cell = (tableView.makeView(withIdentifier: identifier, owner: nil) as? ResultCell) ?? ResultCell()
    cell.identifier = identifier

    cell.configure(
      items[row],
      selected: row == tableView.selectedRow
    )

    return cell
  }

  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    ResultRow()
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    tableView.enumerateAvailableRowViews { _, row in
      guard let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ResultCell else {
        return
      }

      cell.configure(items[row], selected: row == tableView.selectedRow)
    }
  }
}

// MARK: - Private

private final class ResultsTableView: NSTableView {
  override var acceptsFirstResponder: Bool {
    false
  }
}

private final class ResultRow: NSTableRowView {
  private let selectionBackground = NSView()

  override var isSelected: Bool {
    didSet {
      selectionBackground.isHidden = !isSelected
    }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    selectionBackground.layerBackgroundColor = .selectedContentBackgroundColor
    selectionBackground.layer?.cornerCurve = .continuous
    selectionBackground.layer?.cornerRadius = 12
    selectionBackground.isHidden = !isSelected
    addSubview(selectionBackground, positioned: .below, relativeTo: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    selectionBackground.frame = bounds.insetBy(dx: 0, dy: 2)
  }

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    selectionBackground.layerBackgroundColor = .selectedContentBackgroundColor
  }

  override func drawSelection(in dirtyRect: NSRect) {}
}

private final class ResultCell: NSTableCellView {
  private let iconBackground = NSView()
  private let iconGlyph = NSImageView()
  private let title = NSTextField(labelWithString: "")
  private let subtitle = NSTextField(labelWithString: "")
  private var item: QuickSearchItem?
  private var selected = false

  init() {
    super.init(frame: .zero)

    iconBackground.wantsLayer = true
    iconBackground.layer?.cornerCurve = .continuous
    iconBackground.layer?.cornerRadius = 6

    title.maximumNumberOfLines = 1
    title.lineBreakMode = .byTruncatingTail

    subtitle.maximumNumberOfLines = 1
    subtitle.lineBreakMode = .byTruncatingMiddle
    subtitle.font = .systemFont(ofSize: 12)

    for view in [iconBackground, iconGlyph, title, subtitle] {
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
    }

    NSLayoutConstraint.activate([
      iconBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      iconBackground.centerYAnchor.constraint(equalTo: centerYAnchor),
      iconBackground.widthAnchor.constraint(equalToConstant: 28),
      iconBackground.heightAnchor.constraint(equalTo: iconBackground.widthAnchor),
      iconGlyph.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
      iconGlyph.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),

      title.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 12),
      title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      title.topAnchor.constraint(equalTo: topAnchor, constant: 7),

      subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      subtitle.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()

    if let item {
      configure(item, selected: selected)
    }
  }

  func configure(_ item: QuickSearchItem, selected: Bool) {
    self.item = item
    self.selected = selected

    iconGlyph.image = .with(symbolName: item.iconName, pointSize: 18)
    iconGlyph.contentTintColor = selected ? .selectedContentBackgroundColor : .white
    iconBackground.layerBackgroundColor = selected ? .white : item.iconColor

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byTruncatingTail

    // Replace each separator separately to preserve UTF-16 highlight offsets
    let displayTitle = item.title.replacingOccurrences(
      of: "[\\r\\n\\u0085\\u2028\\u2029]",
      with: " ",
      options: .regularExpression
    )

    let text = NSMutableAttributedString(string: displayTitle, attributes: [
      .paragraphStyle: paragraphStyle,
      .font: NSFont.systemFont(ofSize: 15),
      .foregroundColor: selected
        ? NSColor.white.withAlphaComponent(0.85)
        : NSColor.labelColor.resolvedColor(with: effectiveAppearance).withAlphaComponent(0.75),
    ])

    for range in item.highlightedRanges {
      text.addAttributes([
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: selected ? NSColor.white : NSColor.labelColor,
      ], range: range)
    }

    title.attributedStringValue = text
    subtitle.stringValue = item.subtitle
    subtitle.textColor = selected ? .white.withAlphaComponent(0.7) : .secondaryLabelColor

    toolTip = item.subtitle
    setAccessibilityLabel("\(item.title), \(item.subtitle)")
  }
}
