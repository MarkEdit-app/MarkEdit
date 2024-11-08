//
//  FileVersionPicker.swift
//
//  Created by cyan on 10/14/24.
//

import AppKit
import AppKitControls
import DiffKit
import MarkEditKit

@MainActor
public protocol FileVersionPickerDelegate: AnyObject {
  func fileVersionPicker(_ picker: FileVersionPicker, didPickVersion version: NSFileVersion)
  func fileVersionPicker(_ picker: FileVersionPicker, didBecomeSheet: Bool)
}

/**
 A custom file version picker to replace Time Machine due to its performance issues.
 */
public final class FileVersionPicker: NSViewController {
  private let fileURL: URL
  private let currentText: String
  private let localizable: FileVersionLocalizable

  private let topGuide = NSLayoutGuide()
  private let bottomGuide = NSLayoutGuide()

  private let topDivider = DividerView()
  private let bottomDivider = DividerView()

  private let versionMenuButton = NSPopUpButton()
  private let modeMenuButton = NSPopUpButton()

  private let selectButton: NSButton = {
    let button = NSButton()
    button.bezelStyle = .push
    button.bezelColor = .controlAccentColor

    return button
  }()

  private let cancelButton: NSButton = {
    let button = NSButton()
    button.bezelStyle = .push

    return button
  }()

  private let counterView: NSTextField = {
    let label = LabelView()
    label.font = Constants.counterFont
    label.textColor = .labelColor

    return label
  }()

  private let loadingView: NSProgressIndicator = {
    let indicator = NSProgressIndicator()
    indicator.style = .spinning
    indicator.isDisplayedWhenStopped = false

    return indicator
  }()

  private let scrollView: NSScrollView = {
    let scrollView = NSTextView.scrollableTextView()
    scrollView.allowsMagnification = true
    scrollView.minMagnification = 1.0

    let textView = scrollView.textView
    textView?.drawsBackground = false
    textView?.isEditable = false
    textView?.isSelectable = true
    textView?.textContainer?.lineFragmentPadding = 0

    // We avoid using width in textContainerInset as it disrupts the cursor style
    textView?.textContainerInset = CGSize(
      width: 0,
      height: Constants.layoutPadding
    )

    // Instead, we use a tail indent and adjust the leading position to achieve the same effect
    textView?.defaultParagraphStyle = {
      let style = NSMutableParagraphStyle()
      style.tailIndent = -Constants.layoutPadding
      return style
    }()

    // Background color fills the full width to visualize empty lines
    textView?.layoutManager?.showsControlCharacters = true

    return scrollView
  }()

  private lazy var navigateButtons = RoundedNavigateButtons(
    leftAction: { [weak self] in
      self?.goBack()
    },
    rightAction: { [weak self] in
      self?.goForward()
    },
    leftAccessibilityLabel: localizable.previous,
    rightAccessibilityLabel: localizable.next
  )

  private var isDownloading = false {
    didSet {
      scrollView.isHidden = isDownloading
      counterView.isHidden = isDownloading
      view.window?.ignoresMouseEvents = isDownloading

      if isDownloading {
        loadingView.startAnimation(nil)
      } else {
        loadingView.stopAnimation(nil)
      }
    }
  }

  private var allVersions: [NSFileVersion]
  private var localEventMonitor: Any?
  private weak var delegate: FileVersionPickerDelegate?

  public init(
    fileURL: URL,
    currentText: String,
    localVersions: [NSFileVersion],
    localizable: FileVersionLocalizable,
    delegate: FileVersionPickerDelegate
  ) {
    self.fileURL = fileURL
    self.currentText = currentText
    self.allVersions = localVersions
    self.localizable = localizable
    self.delegate = delegate
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func loadView() {
    view = KeyEventView(frame: CGRect(x: 0, y: 0, width: 480, height: 480))
    addChildViews()
    addConstraints()

    resetVersionMenu()
    loadChosenVersion()
    fetchNonlocalVersions()
  }

  override public func viewDidAppear() {
    super.viewDidAppear()
    view.window?.styleMask.remove(.resizable)

    delegate?.fileVersionPicker(self, didBecomeSheet: true)
    addEventMonitor()
  }

  override public func viewDidDisappear() {
    super.viewDidDisappear()

    delegate?.fileVersionPicker(self, didBecomeSheet: false)
    removeEventMonitor()
  }

  override public func viewDidLayout() {
    super.viewDidLayout()
    navigateButtons.setBackgroundColor(.pushButtonBackground)
  }

  override public func cancelOperation(_ sender: Any?) {
    dismiss(self)
  }
}

// MARK: - Private

private extension FileVersionPicker {
  @MainActor
  enum Constants {
    static let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .medium
      return formatter
    }()

    static let barHeight: Double = 48
    static let layoutPadding: Double = 12

    static let counterFont = NSFont.systemFont(ofSize: 12)
    static let menuItemFont = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)

    static let cloudIcon: NSImage = .with(symbolName: "icloud.and.arrow.down", pointSize: 12)
  }

  // MARK: - Set Up

  func addChildViews() {
    view.addLayoutGuide(topGuide)
    view.addLayoutGuide(bottomGuide)

    topDivider.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(topDivider)

    bottomDivider.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(bottomDivider)

    modeMenuButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    modeMenuButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    modeMenuButton.addItems(withTitles: localizable.modeTitles)
    modeMenuButton.target = self
    modeMenuButton.action = #selector(didChangeMode(_:))
    modeMenuButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(modeMenuButton)

    versionMenuButton.target = self
    versionMenuButton.action = #selector(didChangeVersion(_:))
    versionMenuButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(versionMenuButton)

    navigateButtons.isEnabled = true
    navigateButtons.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(navigateButtons)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    loadingView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(loadingView)

    selectButton.setTitle(localizable.revertTitle)
    selectButton.target = self
    selectButton.action = #selector(didPickVersion)
    selectButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(selectButton)

    cancelButton.setTitle(localizable.cancel)
    cancelButton.target = self
    cancelButton.action = #selector(didClickCancel(_:))
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(cancelButton)

    counterView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(counterView)
  }

  func addConstraints() {
    let constraints: [NSLayoutConstraint] = [
      topGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topGuide.topAnchor.constraint(equalTo: view.topAnchor),
      topGuide.heightAnchor.constraint(equalToConstant: Constants.barHeight),

      bottomGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      bottomGuide.heightAnchor.constraint(equalToConstant: Constants.barHeight),

      topDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topDivider.bottomAnchor.constraint(equalTo: topGuide.bottomAnchor),
      topDivider.heightAnchor.constraint(equalToConstant: topDivider.length),

      bottomDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomDivider.topAnchor.constraint(equalTo: bottomGuide.topAnchor),
      bottomDivider.heightAnchor.constraint(equalToConstant: bottomDivider.length),

      navigateButtons.trailingAnchor.constraint(equalTo: topGuide.trailingAnchor, constant: -Constants.layoutPadding),
      navigateButtons.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor),
      navigateButtons.widthAnchor.constraint(equalToConstant: navigateButtons.frame.width),
      navigateButtons.heightAnchor.constraint(equalTo: versionMenuButton.heightAnchor, constant: -2),

      modeMenuButton.trailingAnchor.constraint(equalTo: navigateButtons.leadingAnchor, constant: -Constants.layoutPadding),
      modeMenuButton.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor),

      versionMenuButton.leadingAnchor.constraint(equalTo: topGuide.leadingAnchor, constant: Constants.layoutPadding),
      versionMenuButton.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor),
      versionMenuButton.trailingAnchor.constraint(equalTo: modeMenuButton.leadingAnchor, constant: -Constants.layoutPadding),

      selectButton.trailingAnchor.constraint(equalTo: bottomGuide.trailingAnchor, constant: -Constants.layoutPadding),
      selectButton.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor),

      cancelButton.trailingAnchor.constraint(equalTo: selectButton.leadingAnchor, constant: -Constants.layoutPadding),
      cancelButton.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor),

      counterView.leadingAnchor.constraint(equalTo: bottomGuide.leadingAnchor, constant: Constants.layoutPadding),
      counterView.trailingAnchor.constraint(lessThanOrEqualTo: cancelButton.leadingAnchor, constant: -Constants.layoutPadding),
      counterView.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor),

      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.layoutPadding),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: topGuide.bottomAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomGuide.topAnchor),

      loadingView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
      loadingView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
    ]

    NSLayoutConstraint.activate(constraints)
  }

  func formattedDate(for version: NSFileVersion) -> NSAttributedString {
    NSAttributedString(
      string: Constants.dateFormatter.string(from: version.modificationDate ?? .distantPast),
      attributes: [.font: Constants.menuItemFont]
    )
  }

  // MARK: - Action Handlers

  @objc func didChangeVersion(_ sender: NSButton) {
    loadChosenVersion()
  }

  @objc func didChangeMode(_ sender: NSButton) {
    loadChosenVersion(scrollToTop: false)
  }

  @objc func didClickCancel(_ sender: NSButton) {
    dismiss(self)
  }

  @objc func didPickVersion() {
    delegate?.fileVersionPicker(self, didPickVersion: allVersions[versionMenuButton.indexOfSelectedItem])
    dismiss(self)
  }

  func goBack() {
    gotoVersion(at: max(0, versionMenuButton.indexOfSelectedItem - 1))
  }

  func goForward() {
    gotoVersion(at: min(allVersions.count - 1, versionMenuButton.indexOfSelectedItem + 1))
  }

  func gotoVersion(at index: Int) {
    guard versionMenuButton.indexOfSelectedItem != index else {
      return NSSound.beep()
    }

    versionMenuButton.selectItem(at: index)
    loadChosenVersion()
  }

  // MARK: - Updating

  func fetchNonlocalVersions() {
    Task {
      let nonlocal = try await NSFileVersion.nonlocalVersionsOfItem(at: self.fileURL)
      DispatchQueue.main.async {
        self.allVersions = (self.allVersions + nonlocal).newestToOldest()
        self.resetVersionMenu()
      }
    }
  }

  func resetVersionMenu() {
    let selectedObject = versionMenuButton.selectedItem?.representedObject as? NSFileVersion
    versionMenuButton.menu?.removeAllItems()

    for version in allVersions {
      let item = NSMenuItem()
      let attributedTitle = NSMutableAttributedString(attributedString: formattedDate(for: version))

      if version.needsDownloading {
        let attachment = NSTextAttachment()
        let image = Constants.cloudIcon
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -4, width: image.size.width, height: image.size.height)
        attributedTitle.append(NSAttributedString(string: "  "))
        attributedTitle.append(NSAttributedString(attachment: attachment))
      }

      item.attributedTitle = attributedTitle
      item.representedObject = version
      versionMenuButton.menu?.addItem(item)
    }

    if let index = (versionMenuButton.menu?.items.firstIndex {
      ($0.representedObject as? NSFileVersion) == selectedObject
    }) {
      versionMenuButton.selectItem(at: index)
    }
  }

  func loadChosenVersion(scrollToTop: Bool = true) {
    let version = allVersions[versionMenuButton.indexOfSelectedItem]
    version.fetchLocalContents(
      startedDownloading: {
        self.isDownloading = true
      },
      contentsFetched: {
        if let newVersion = try? Data(contentsOf: version.url).toString() {
          self.renderDifferences(newVersion: newVersion, scrollToTop: scrollToTop)
        } else {
          Logger.log(.error, "Failed to get file contents of version: \(version)")
        }

        self.isDownloading = false
        self.versionMenuButton.selectedItem?.attributedTitle = self.formattedDate(for: version)
      }
    )
  }

  func renderDifferences(newVersion: String, scrollToTop: Bool) {
    let mode = modeMenuButton.indexOfSelectedItem // lines, words, chars
    let diffs = Diff.compute(
      oldValue: currentText,
      newValue: newVersion,
      mode: Diff.Mode.allCases[mode]
    )

    if scrollToTop {
      scrollView.setContentOffset(.zero)
    }

    scrollView.setAttributedText(diffs.attributedText(styledNewlines: mode == 0))
    counterView.attributedStringValue = diffs.counterText
  }

  // MARK: - Event Handling

  final class KeyEventView: NSView {
    override var acceptsFirstResponder: Bool {
      true
    }
  }

  func addEventMonitor() {
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
        self?.goBack()
        return nil
      case .kVK_RightArrow:
        self?.goForward()
        return nil
      case .kVK_DownArrow:
        self?.scrollView.scrollTextViewDown()
        return nil
      case .kVK_UpArrow:
        self?.scrollView.scrollTextViewUp()
        return nil
      case .kVK_Space:
        self?.gotoVersion(at: NSApp.shiftKeyIsPressed ? ((self?.allVersions.count ?? 1) - 1) : 0)
        return nil
      default:
        return event
      }
    }
  }

  func removeEventMonitor() {
    if let monitor = localEventMonitor {
      NSEvent.removeMonitor(monitor)
      localEventMonitor = nil
    }
  }
}
