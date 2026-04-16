//
//  TabSwitcherView.swift
//
//  Created by lamchau on 4/16/26.
//

import AppKit

final class TabSwitcherView: NSView {
  private enum Constants {
    static let cornerRadius: Double = 12
    static let padding: Double = 8
    static let iconInset: Double = 4
    static let dividerSpacing: Double = 4
    static let searchHeight: Double = 36
    static let rowHeight: Double = 32
    static let iconWidth: Double = 20
  }

  private lazy var effectView: NSView = {
    let view = effectViewType.init()
    (view as? NSVisualEffectView)?.material = .popover

    return view
  }()

  private let textField: NSTextField = {
    let textField = NSTextField()
    textField.font = .systemFont(ofSize: 16, weight: .light)
    textField.focusRingType = .none
    textField.drawsBackground = false
    textField.isBezeled = false

    return textField
  }()

  private let scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = false

    return scrollView
  }()

  private let tableView: NSTableView = {
    let tableView = NSTableView()
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.rowHeight = Constants.rowHeight
    tableView.selectionHighlightStyle = .regular
    tableView.intercellSpacing = NSSize(width: 0, height: 2)

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("tab"))
    column.isEditable = false
    tableView.addTableColumn(column)

    return tableView
  }()

  private let effectViewType: NSView.Type
  private var allItems: [TabSwitcherItem] = []
  private var filteredItems: [TabSwitcherItem] = []

  private lazy var emptyLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 13, weight: .regular)
    label.textColor = .secondaryLabelColor
    label.alignment = .center
    label.isHidden = true
    label.translatesAutoresizingMaskIntoConstraints = false

    return label
  }()

  init(
    effectViewType: NSView.Type,
    frame: CGRect,
    placeholder: String,
    accessibilityHelp: String,
    emptyMessage: String,
    items: [TabSwitcherItem],
    initialSelection: Int = 0
  ) {
    self.effectViewType = effectViewType
    self.allItems = items
    self.filteredItems = items
    super.init(frame: frame)

    emptyLabel.stringValue = emptyMessage

    wantsLayer = true
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = Constants.cornerRadius
    layer?.masksToBounds = true

    setupSubviews(placeholder: placeholder, accessibilityHelp: accessibilityHelp)
    selectRow(initialSelection)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - NSTextFieldDelegate

extension TabSwitcherView: NSTextFieldDelegate {
  func controlTextDidChange(_ obj: Notification) {
    filterItems()
  }

  func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
    switch selector {
    case #selector(insertNewline(_:)):
      activateSelectedItem()
      return true
    case #selector(moveUp(_:)):
      moveSelection(by: -1)
      return true
    case #selector(moveDown(_:)):
      moveSelection(by: 1)
      return true
    case #selector(cancelOperation(_:)):
      window?.orderOut(self)
      return true
    default:
      return false
    }
  }
}

// MARK: - NSTableViewDataSource

extension TabSwitcherView: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    filteredItems.count
  }
}

// MARK: - NSTableViewDelegate

extension TabSwitcherView: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let identifier = NSUserInterfaceItemIdentifier("TabCell")
    let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? TabSwitcherCell
      ?? TabSwitcherCell(identifier: identifier)

    let item = filteredItems[row]
    cell.configure(title: item.title, subtitle: item.subtitle)

    return cell
  }
}

private extension TabSwitcherView {
  func setupSubviews(placeholder: String, accessibilityHelp: String) {
    effectView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(effectView)

    let iconView = NSImageView(image: .with(symbolName: "magnifyingglass", pointSize: 16, weight: .light))
    iconView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(iconView)

    textField.placeholderString = placeholder
    textField.setAccessibilityHelp(accessibilityHelp)
    textField.delegate = self
    textField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(textField)

    let divider = NSBox()
    divider.boxType = .separator
    divider.translatesAutoresizingMaskIntoConstraints = false
    addSubview(divider)

    tableView.dataSource = self
    tableView.delegate = self
    tableView.doubleAction = #selector(tableViewDoubleClicked)
    tableView.target = self
    scrollView.documentView = tableView
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(scrollView)

    addSubview(emptyLabel)

    NSLayoutConstraint.activate([
      effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
      effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
      effectView.topAnchor.constraint(equalTo: topAnchor),
      effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

      iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding + Constants.iconInset),
      iconView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding),
      iconView.heightAnchor.constraint(equalToConstant: Constants.searchHeight - Constants.padding),
      iconView.widthAnchor.constraint(equalToConstant: Constants.iconWidth),

      textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Constants.padding),
      textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding),
      textField.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

      divider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding),
      divider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding),
      divider.topAnchor.constraint(equalTo: topAnchor, constant: Constants.searchHeight + Constants.padding),

      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: Constants.dividerSpacing),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding),

      emptyLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
      emptyLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
    ])
  }

  func filterItems() {
    let query = textField.stringValue

    if query.isEmpty {
      filteredItems = allItems
    } else {
      filteredItems = allItems.filter {
        $0.title.localizedCaseInsensitiveContains(query) || $0.subtitle.localizedCaseInsensitiveContains(query)
      }
    }

    tableView.reloadData()
    emptyLabel.isHidden = !filteredItems.isEmpty
    selectRow(0)
  }

  func moveSelection(by delta: Int) {
    guard !filteredItems.isEmpty else {
      return
    }

    let current = max(tableView.selectedRow, 0)
    let next = (current + delta + filteredItems.count) % filteredItems.count
    selectRow(next)
  }

  func selectRow(_ row: Int) {
    guard row >= 0, row < filteredItems.count else {
      return
    }

    tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    tableView.scrollRowToVisible(row)
  }

  func activateSelectedItem() {
    let row = tableView.selectedRow

    guard row >= 0, row < filteredItems.count else {
      return
    }

    let item = filteredItems[row]
    window?.orderOut(self)
    item.handler()
  }

  @objc func tableViewDoubleClicked() {
    let row = tableView.clickedRow

    guard row >= 0, row < filteredItems.count else {
      return
    }

    selectRow(row)
    activateSelectedItem()
  }
}

// MARK: - TabSwitcherCell

private final class TabSwitcherCell: NSTableCellView {
  private let titleLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 13, weight: .regular)
    label.lineBreakMode = .byTruncatingMiddle

    return label
  }()

  private let subtitleLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 11, weight: .regular)
    label.textColor = .secondaryLabelColor
    label.lineBreakMode = .byTruncatingHead

    return label
  }()

  init(identifier: NSUserInterfaceItemIdentifier) {
    super.init(frame: .zero)
    self.identifier = identifier
    self.textField = titleLabel

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
      subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
      subtitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, subtitle: String) {
    titleLabel.stringValue = title
    subtitleLabel.stringValue = subtitle
    subtitleLabel.isHidden = subtitle.isEmpty
  }
}
