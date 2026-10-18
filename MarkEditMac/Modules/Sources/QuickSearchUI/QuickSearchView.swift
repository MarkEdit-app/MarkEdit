//
//  QuickSearchView.swift
//
//  Created by cyan on 1/17/23.
//

import AppKit
import AppKitExtensions

final class QuickSearchView: NSView {
  var tintColor: NSColor? {
    get {
      tintView.layerBackgroundColor
    }
    set {
      tintView.layerBackgroundColor = newValue
    }
  }

  private enum Constants {
    static let cornerRadius: Double = 20
    static let horizontalPadding: Double = 12
    static let iconSpacing: Double = 8
  }

  private lazy var effectView: NSView = {
    let effectView = effectViewType.init()
    (effectView as? NSVisualEffectView)?.material = .popover

    return effectView
  }()

  private let textField: NSTextField = {
    let textField = NSTextField()
    textField.font = .systemFont(ofSize: 20, weight: .light)
    textField.focusRingType = .none
    textField.drawsBackground = false
    textField.isBezeled = false

    return textField
  }()

  private let tintView = NSView()
  private let iconView: NSImageView
  private let effectViewType: NSView.Type
  private let handler: (String) -> Bool
  private var textTrailingConstraint: NSLayoutConstraint?
  private var filterButton: NSPopUpButton?
  private var inputCenterConstraints: [NSLayoutConstraint] = []
  private var resultsConfiguration: QuickSearchResultsConfiguration?
  private var resultsView: QuickSearchResultsView?

  var resultsHeight: Double {
    resultsView?.preferredHeight ?? 0
  }

  init(
    effectViewType: NSView.Type,
    tintColor: NSColor?,
    frame: CGRect,
    placeholder: String,
    accessibilityHelp: String,
    iconName: String,
    defaultText: String? = nil,
    handler: @escaping (String) -> Bool
  ) {
    self.effectViewType = effectViewType
    self.handler = handler
    iconView = NSImageView(image: .with(symbolName: iconName, pointSize: 20, weight: .light))
    super.init(frame: frame)

    wantsLayer = true
    clipsToBounds = true
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = Constants.cornerRadius

    effectView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(effectView)

    tintView.layerBackgroundColor = tintColor
    tintView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(tintView)

    iconView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(iconView)

    textField.placeholderString = placeholder
    textField.setAccessibilityHelp(accessibilityHelp)
    textField.delegate = self
    textField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(textField)

    let textTrailing = textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalPadding)
    textTrailingConstraint = textTrailing

    NSLayoutConstraint.activate([
      effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
      effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
      effectView.topAnchor.constraint(equalTo: topAnchor),
      effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

      tintView.leadingAnchor.constraint(equalTo: leadingAnchor),
      tintView.trailingAnchor.constraint(equalTo: trailingAnchor),
      tintView.topAnchor.constraint(equalTo: topAnchor),
      tintView.bottomAnchor.constraint(equalTo: bottomAnchor),

      iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalPadding),
      iconView.heightAnchor.constraint(equalToConstant: iconView.frame.height),
      iconView.widthAnchor.constraint(equalToConstant: iconView.frame.width),

      textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Constants.iconSpacing),
      textTrailing,
    ])

    inputCenterConstraints = [
      iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
      textField.centerYAnchor.constraint(equalTo: centerYAnchor),
    ]

    NSLayoutConstraint.activate(inputCenterConstraints)
    if let defaultText {
      textField.stringValue = defaultText
      textField.selectAll()
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configureResults(_ configuration: QuickSearchResultsConfiguration) {
    resultsConfiguration = configuration

    for constraint in inputCenterConstraints {
      constraint.isActive = false

      if let view = constraint.firstItem as? NSView {
        view.centerYAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
      }
    }

    let resultsView = QuickSearchResultsView(onActivate: configuration.onActivate)
    resultsView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(resultsView)

    NSLayoutConstraint.activate([
      resultsView.topAnchor.constraint(equalTo: topAnchor, constant: 48),
      resultsView.leadingAnchor.constraint(equalTo: leadingAnchor),
      resultsView.trailingAnchor.constraint(equalTo: trailingAnchor),
      resultsView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    self.resultsView = resultsView
    if let menu = configuration.filterMenu {
      configureFilterMenu(menu)
    }
  }

  func updateResults(_ items: [QuickSearchItem], message: String?, preserveSelection: Bool) {
    resultsView?.update(items, message: message, preserveSelection: preserveSelection)
  }

  func setInteractionEnabled(_ enabled: Bool) {
    textField.isEnabled = enabled
    filterButton?.isEnabled = enabled
    resultsView?.isEnabled = enabled
  }

  func focusInput() {
    window?.makeFirstResponder(textField)
  }

  func setFilterActive(_ active: Bool) {
    filterButton?.contentTintColor = active ? .controlAccentColor : .secondaryLabelColor
  }

  func setPlaceholder(_ placeholder: String) {
    textField.placeholderString = placeholder
  }

  func performFilterKeyEquivalent(with event: NSEvent) -> Bool {
    guard let filterButton, filterButton.isEnabled,
          (textField.currentEditor() as? NSTextView)?.hasMarkedText() != true else {
      return false
    }

    return filterButton.menu?.performKeyEquivalent(with: event) == true
  }

  private func configureFilterMenu(_ menu: NSMenu) {
    let button = NSPopUpButton(frame: .zero, pullsDown: true)
    let iconItem = NSMenuItem(title: menu.title, action: nil, keyEquivalent: "")
    iconItem.image = .with(symbolName: "line.3.horizontal.decrease", pointSize: 20, weight: .light)
    iconItem.isHidden = true
    menu.insertItem(iconItem, at: 0)

    button.menu = menu
    button.isBordered = false
    button.imagePosition = .imageOnly
    button.contentTintColor = .secondaryLabelColor
    button.toolTip = menu.title
    button.setAccessibilityLabel(menu.title)
    (button.cell as? NSPopUpButtonCell)?.arrowPosition = .noArrow
    button.translatesAutoresizingMaskIntoConstraints = false
    addSubview(button)

    textTrailingConstraint?.isActive = false
    NSLayoutConstraint.activate([
      button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalPadding),
      button.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
      button.widthAnchor.constraint(equalTo: iconView.widthAnchor),
      button.heightAnchor.constraint(equalTo: iconView.heightAnchor),
      textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -Constants.iconSpacing),
    ])

    filterButton = button
  }
}

// MARK: - NSTextFieldDelegate

extension QuickSearchView: NSTextFieldDelegate {
  func controlTextDidChange(_ notification: Notification) {
    guard (textField.currentEditor() as? NSTextView)?.hasMarkedText() != true else {
      return
    }

    resultsConfiguration?.onQueryChange(textField.stringValue)
  }

  func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
    if let resultsView {
      guard !textView.hasMarkedText() else {
        return false
      }

      switch selector {
      case #selector(insertTab(_:)):
        guard let filterButton, filterButton.isEnabled, let menu = filterButton.menu else {
          return false
        }

        menu.popUp(
          positioning: menu.items.first { $0.state == .on },
          at: NSPoint(x: filterButton.bounds.minX, y: filterButton.bounds.midY),
          in: filterButton
        )

        return true
      case #selector(moveDown(_:)):
        resultsView.moveSelection(by: 1)
        return true
      case #selector(moveUp(_:)):
        resultsView.moveSelection(by: -1)
        return true
      case #selector(insertNewline(_:)):
        resultsView.activateSelection()
        return true
      default:
        return false
      }
    }

    switch selector {
    case #selector(insertNewline(_:)):
      submit()
      return true
    default:
      return false
    }
  }
}

// MARK: - Private

private extension QuickSearchView {
  func submit() {
    guard handler(textField.stringValue) else {
      NSSound.beep()
      textField.currentEditor()?.selectAll(nil)
      return
    }

    window?.orderOut(self)
  }
}
