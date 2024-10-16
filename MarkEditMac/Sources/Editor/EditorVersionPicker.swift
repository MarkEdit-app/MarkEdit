//
//  EditorVersionPicker.swift
//  MarkEditMac
//
//  Created by cyan on 2024/10/14.
//

import AppKit
import AppKitControls
import DiffKit

protocol EditorVersionPickerDelegate: AnyObject {
  func editorVersionPicker(_ picker: EditorVersionPicker, didPickVersion version: NSFileVersion)
  func editorVersionPickerDidDisappear(_ picker: EditorVersionPicker)
}

/**
 Homemade version picker to replace the time machine, which has extremely bad performance.
 */
final class EditorVersionPicker: NSViewController {
  private let fileURL: URL
  private let current: String
  private var versions: [NSFileVersion]

  private let topGuide = NSLayoutGuide()
  private let bottomGuide = NSLayoutGuide()
  private let topDivider = DividerView()
  private let bottomDivider = DividerView()

  private let modePopUp = NSPopUpButton()
  private let versionPopUp = NSPopUpButton()

  private let doneButton = {
    let button = NSButton()
    button.bezelStyle = .push
    button.bezelColor = .controlAccentColor
    button.setTitle("Pick This Version")

    return button
  }()

  private let cancelButton = {
    let button = NSButton()
    button.bezelStyle = .push
    button.setTitle("Cancel")

    return button
  }()

  private let countView: LabelView = {
    let label = LabelView()
    label.font = .systemFont(ofSize: 12)
    label.textColor = .labelColor
    return label
  }()

  private let spinner: NSProgressIndicator = {
    let spinner = NSProgressIndicator()
    spinner.style = .spinning
    spinner.isDisplayedWhenStopped = false

    return spinner
  }()

  private let scrollView = NSTextView.scrollableTextView()

  private lazy var navigateButtons = EditorFindButtons(
    leftAction: { [weak self] in
      self?.navigateBack()
    },
    rightAction: { [weak self] in
      self?.navigateForward()
    }
  )

  private var isDownloading = false
  private var localEventMonitor: Any?
  private weak var delegate: EditorVersionPickerDelegate?

  deinit {
    if let monitor = localEventMonitor {
      NSEvent.removeMonitor(monitor)
      localEventMonitor = nil
    }
  }

  init(fileURL: URL, current: String, versions: [NSFileVersion], delegate: EditorVersionPickerDelegate) {
    self.fileURL = fileURL
    self.current = current
    self.versions = versions
    self.delegate = delegate
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = MyView(frame: CGRect(x: 0, y: 0, width: 480, height: 480))
    view.addLayoutGuide(topGuide)
    view.addLayoutGuide(bottomGuide)

    topDivider.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(topDivider)

    bottomDivider.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(bottomDivider)

    modePopUp.addItems(withTitles: Diff.Mode.allCases.map {
      "\($0.rawValue.capitalized) Diff"
    })

    modePopUp.selectItem(at: 0)
    modePopUp.translatesAutoresizingMaskIntoConstraints = false
    modePopUp.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    modePopUp.target = self
    modePopUp.action = #selector(didChangeMode(_:))

    modePopUp.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    view.addSubview(modePopUp)

    versionPopUp.selectItem(at: 0)
    versionPopUp.target = self
    versionPopUp.action = #selector(didChangeVersion(_:))

    versionPopUp.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(versionPopUp)

    navigateButtons.isEnabled = true
    navigateButtons.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(navigateButtons)

    doneButton.translatesAutoresizingMaskIntoConstraints = false
    doneButton.target = self
    doneButton.action = #selector(didPickVersion)
    view.addSubview(doneButton)

    cancelButton.target = self
    cancelButton.action = #selector(didClickCancel(_:))
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(cancelButton)

    countView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(countView)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    spinner.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(spinner)

    NSLayoutConstraint.activate([
      topGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topGuide.topAnchor.constraint(equalTo: view.topAnchor),
      topGuide.heightAnchor.constraint(equalToConstant: Constants.topBottomHeight),

      bottomGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      bottomGuide.heightAnchor.constraint(equalToConstant: Constants.topBottomHeight),

      topDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topDivider.bottomAnchor.constraint(equalTo: topGuide.bottomAnchor),
      topDivider.heightAnchor.constraint(equalToConstant: topDivider.length),

      bottomDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomDivider.topAnchor.constraint(equalTo: bottomGuide.topAnchor),
      bottomDivider.heightAnchor.constraint(equalToConstant: bottomDivider.length),

      navigateButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.layoutPadding),
      navigateButtons.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor),
      navigateButtons.widthAnchor.constraint(equalToConstant: navigateButtons.frame.width),
      navigateButtons.heightAnchor.constraint(equalTo: versionPopUp.heightAnchor, constant: -2),

      modePopUp.trailingAnchor.constraint(equalTo: navigateButtons.leadingAnchor, constant: -Constants.layoutPadding),
      modePopUp.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor),

      versionPopUp.leadingAnchor.constraint(equalTo: topGuide.leadingAnchor, constant: Constants.layoutPadding),
      versionPopUp.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor),
      versionPopUp.trailingAnchor.constraint(equalTo: modePopUp.leadingAnchor, constant: -Constants.layoutPadding),

      doneButton.trailingAnchor.constraint(equalTo: bottomGuide.trailingAnchor, constant: -Constants.layoutPadding),
      doneButton.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor),

      cancelButton.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -Constants.layoutPadding),
      cancelButton.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor),

      countView.leadingAnchor.constraint(equalTo: bottomGuide.leadingAnchor, constant: Constants.layoutPadding),
      countView.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor),

      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: topGuide.bottomAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomGuide.topAnchor),

      spinner.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
    ])

    if let textView = scrollView.documentView as? NSTextView {
      textView.isEditable = false
      textView.textContainerInset = CGSize(width: Constants.layoutPadding, height: Constants.layoutPadding)
      textView.textContainer?.lineFragmentPadding = 0
      textView.drawsBackground = false
    }

    addVersions(versions: versions)
    renderDiffs(resetOffset: false)
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    view.window?.styleMask.remove(.resizable)

    Task {
      let nonlocal = (try await NSFileVersion.nonlocalVersionsOfItem(at: self.fileURL)).newestToOldest
      DispatchQueue.main.async {
        self.versionPopUp.menu?.addItem(.separator())
        self.versions.append(contentsOf: nonlocal)
        self.addVersions(versions: nonlocal)
      }
    }

    localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let window = self?.view.window, window.isKeyWindow else {
        return event
      }

      guard let isDownloading = self?.isDownloading, !isDownloading else {
        return event
      }

      guard !NSWorkspace.shared.isVoiceOverEnabled else {
        return event
      }

      switch event.keyCode {
      case .kVK_Return:
        self?.didPickVersion()
        return nil
      case .kVK_LeftArrow:
        self?.navigateBack()
        return nil
      case .kVK_RightArrow:
        self?.navigateForward()
        return nil
      case .kVK_DownArrow:
        (self?.scrollView.documentView as? NSTextView)?.scrollPageDown(nil)
        return nil
      case .kVK_UpArrow:
        (self?.scrollView.documentView as? NSTextView)?.scrollPageUp(nil)
        return nil
      default:
        return event
      }
    }
  }

  override func viewDidDisappear() {
    delegate?.editorVersionPickerDidDisappear(self)
    super.viewDidDisappear()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    navigateButtons.setBackgroundColor(.pushButtonBackground)
  }

  override func cancelOperation(_ sender: Any?) {
    guard !NSWorkspace.shared.isVoiceOverEnabled else {
      return
    }

    dismiss(self)
  }
}

// MARK: - Private

private extension EditorVersionPicker {
  enum Constants {
    static let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .medium
      return formatter
    }()

    static let topBottomHeight: Double = 48
    static let layoutPadding: Double = 12
    static let digitFont = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    static let monoFont = NSFont.monospacedSystemFont(ofSize: 12)
  }

  @objc func didChangeVersion(_ sender: NSPopUpButton) {
    renderDiffs()
  }

  @objc func didChangeMode(_ sender: NSPopUpButton) {
    renderDiffs(resetOffset: false)
  }

  @objc func didClickCancel(_ sender: NSButton) {
    dismiss(self)
  }

  @objc func didPickVersion() {
    delegate?.editorVersionPicker(self, didPickVersion: versions[versionPopUp.indexOfSelectedItem])
    dismiss(self)
  }

  func addVersions(versions: [NSFileVersion]) {
    for version in versions {
      let date = version.modificationDate ?? .distantPast
      let item = NSMenuItem()
      item.attributedTitle = NSAttributedString(
        string: Constants.dateFormatter.string(from: date),
        attributes: [.font: Constants.digitFont]
      )

      item.tag = versionPopUp.itemArray.count
      versionPopUp.menu?.addItem(item)
    }
  }

  func renderDiffs(resetOffset: Bool = true) {
    let version = versions[versionPopUp.indexOfSelectedItem]
    version.fetchLocalContents(
      startedDownloading: {
        self.countView.isHidden = true
        self.scrollView.isHidden = true
        self.isDownloading = true
        self.spinner.startAnimation(nil)
        self.view.window?.ignoresMouseEvents = true
      },
      contentsFetched: {
        if let newValue = try? Data(contentsOf: version.url).toString() {
          self.generateDiffs(newValue: newValue, resetOffset: resetOffset)
        }

        self.spinner.stopAnimation(nil)
        self.countView.isHidden = false
        self.scrollView.isHidden = false
        self.isDownloading = false
        self.view.window?.ignoresMouseEvents = false
      }
    )
  }

  func generateDiffs(newValue: String, resetOffset: Bool) {
    let result = NSMutableAttributedString(string: "")
    let diffs = Diff.compute(oldValue: current, newValue: newValue, mode: Diff.Mode.allCases[modePopUp.indexOfSelectedItem])
    var addedCount = 0
    var removedCount = 0

    diffs.forEach {
      var attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: $0.textColor,
        .font: Constants.monoFont,
      ]

      if let backgroundColor = $0.backgroundColor {
        attributes[.backgroundColor] = backgroundColor
      }

      if $0.added {
        addedCount += 1
      } else if $0.removed {
        removedCount += 1
      }

      result.append(NSAttributedString(string: $0.value, attributes: attributes))
    }

    let textView = scrollView.documentView as? NSTextView
    textView?.textStorage?.setAttributedString(result)

    if resetOffset {
      textView?.scroll(.zero)
    }

    let countString = NSMutableAttributedString(string: "")
    if addedCount > 0 {
      countString.append(NSAttributedString(
        string: " +\(addedCount) ",
        attributes: [
          .foregroundColor: addedTextColor,
          .backgroundColor: addedBackgroundColor,
          .font: Constants.monoFont,
        ]
      ))

      countString.append(NSAttributedString(string: " "))
    }

    if removedCount > 0 {
      countString.append(NSAttributedString(
        string: " -\(removedCount) ",
        attributes: [
          .foregroundColor: removedTextColor,
          .backgroundColor: removedBackgroundColor,
          .font: Constants.monoFont,
        ]
      ))
    }

    countView.attributedStringValue = countString
  }

  func navigateBack() {
    if versionPopUp.indexOfSelectedItem > 0 {
      versionPopUp.selectItem(at: versionPopUp.indexOfSelectedItem - 1)
      renderDiffs()
    } else {
      NSSound.beep()
    }
  }

  func navigateForward() {
    if versionPopUp.indexOfSelectedItem < versions.count - 1 {
      versionPopUp.selectItem(at: versionPopUp.indexOfSelectedItem + 1)
      renderDiffs()
    } else {
      NSSound.beep()
    }
  }
}

private final class MyView: NSView {
  override var acceptsFirstResponder: Bool { true }
}

private extension NSButton {
  func setTitle(_ title: String, font: NSFont = .systemFont(ofSize: 12)) {
    attributedTitle = NSAttributedString(
      string: title,
      attributes: [.font: font]
    )
  }
}

private extension Diff.Result {
  var textColor: NSColor {
    if added {
      return addedTextColor
    } else if removed {
      return removedTextColor
    } else {
      return .labelColor
    }
  }

  var backgroundColor: NSColor? {
    if added {
      return addedBackgroundColor
    } else if removed {
      return removedBackgroundColor
    } else {
      return nil
    }
  }
}

private let addedTextColor: NSColor = .theme(lightHexCode: 0x007757, darkHexCode: 0x46c146)
private let addedBackgroundColor: NSColor = .theme(lightHexCode: 0xe8fcf3, darkHexCode: 0x415041)
private let removedTextColor: NSColor = .theme(lightHexCode: 0xc71f24, darkHexCode: 0xef856d)
private let removedBackgroundColor: NSColor = .theme(lightHexCode: 0xffebeb, darkHexCode: 0x4a3532)
