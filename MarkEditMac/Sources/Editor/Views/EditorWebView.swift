//
//  EditorWebView.swift
//  MarkEditMac
//
//  Created by cyan on 12/16/22.
//

import WebKit
import MarkEditKit

/**
 https://github.com/WebKit/WebKit/blob/main/Source/WebKit/Shared/API/c/WKContextMenuItem.cpp
 */
enum WKContextMenuItemTag: Int {
  case downloadImage = 5
  case copy = 8
  case reload = 12
  case cut = 13
  case paste = 14
  case showFonts = 41
  case defaultDirection = 52
  case textDirectionDefault = 59
  case copyLinkWithHighlight = 102

  /**
   Customized item that shows the search operations.
   */
  case searchMenu = 0xbadbabe
}

enum EditorWebViewMenuAction {
  case findSelection
  case selectAllOccurrences
}

@MainActor
protocol EditorWebViewActionDelegate: AnyObject {
  func editorWebViewIsReadOnlyMode(_ webView: EditorWebView) -> Bool
  func editorWebViewSearchOperationsMenuItem(_ webView: EditorWebView) -> NSMenuItem?
  func editorWebViewResignFirstResponder(_ webView: EditorWebView)
  func editorWebView(_ webView: EditorWebView, mouseDownWith event: NSEvent)
  func editorWebView(_ webView: EditorWebView, didSelect menuAction: EditorWebViewMenuAction)

  func editorWebView(
    _ webView: EditorWebView,
    didPerform textAction: EditorTextAction,
    sender: Any?
  )

  func editorWebViewEditorState(_ webView: EditorWebView) async -> (
    hasFocus: Bool,
    hasSelection: Bool
  )
}

/**
 Lightweight wrapper for WKWebView used in editors.
 */
final class EditorWebView: WKWebView {
  static let baseURL = URL(string: "http://localhost/")
  static let userDefinedContextMenuID = NSUserInterfaceItemIdentifier("userDefinedContextMenu")
  weak var actionDelegate: EditorWebViewActionDelegate?

  override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)
    actionDelegate?.editorWebView(self, mouseDownWith: event)
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    // Silence the incorrect "beep" in WebKit
    if event.modifierFlags.contains([.control, .command]),
       event.keyCode == .kVK_LeftArrow || event.keyCode == .kVK_RightArrow {
      // Event will be handled in CoreEditor instead
      return false
    }

    return super.performKeyEquivalent(with: event)
  }

  override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
    guard menu.identifier != Self.userDefinedContextMenuID else {
      return super.willOpenMenu(menu, with: event)
    }

    menu.items = menu.items.filter { item in
      // Remove "Download Image"
      if item.tag == WKContextMenuItemTag.downloadImage.rawValue {
        return false
      }

      // Remove "Reload"
      if item.tag == WKContextMenuItemTag.reload.rawValue {
        return false
      }

      // Remove "Copy Link with Highlight"
      if item.tag == WKContextMenuItemTag.copyLinkWithHighlight.rawValue {
        return false
      }

      // Remove "Font", "Paragraph Direction", "Selection Direction"
      if item.submenuContains(anyOf: .showFonts, .defaultDirection, .textDirectionDefault) {
        return false
      }

      return true
    }

    // Operations like select all in selection, replace all in selection, etc
    if let searchMenuItem = actionDelegate?.editorWebViewSearchOperationsMenuItem(self) {
      menu.insertItem(searchMenuItem, at: 0)
      menu.insertItem(.separator(), at: 1)
    }

    menu.addItem(.separator())

    let findSelectionItem = menu.addItem(
      withTitle: Localized.Search.findSelection,
      action: #selector(findSelection(_:))
    )

    let selectAllOccurrencesItem = menu.addItem(
      withTitle: Localized.Search.selectAllOccurrences,
      action: #selector(selectAllOccurrences(_:))
    )

    if AppDesign.menuIconEvolution {
      findSelectionItem.image = NSImage(systemSymbolName: "text.page.badge.magnifyingglass", accessibilityDescription: nil)
      selectAllOccurrencesItem.image = NSImage(systemSymbolName: "selection.pin.in.out", accessibilityDescription: nil)
    }

    // Only add text format items when it's not read-only
    if !(actionDelegate?.editorWebViewIsReadOnlyMode(self) ?? false) {
      let item = NSMenuItem()
      item.title = Localized.Toolbar.textFormat
      item.submenu = NSApp.appDelegate?.textFormatMenu?.copiedMenu

      if AppDesign.menuIconEvolution {
        item.image = NSImage(systemSymbolName: "bold.italic.underline", accessibilityDescription: nil)
      }

      menu.addItem(item)
    }

    menu.addItem(.separator())
    updateMenuItems(menu: menu)
    super.willOpenMenu(menu, with: event)

    // Text selection might have changed after showing the menu
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.updateMenuItems(menu: menu)
    }
  }

  override func resignFirstResponder() -> Bool {
    actionDelegate?.editorWebViewResignFirstResponder(self)
    return super.resignFirstResponder()
  }

  override func accessibilityRole() -> NSAccessibility.Role? {
    .textArea
  }
}

// MARK: - Private

private extension EditorWebView {
  @objc func findSelection(_ sender: NSMenuItem) {
    actionDelegate?.editorWebView(self, didSelect: .findSelection)
  }

  @objc func selectAllOccurrences(_ sender: NSMenuItem) {
    actionDelegate?.editorWebView(self, didSelect: .selectAllOccurrences)
  }

  func updateMenuItems(menu: NSMenu) {
    Task {
      let editorState = await actionDelegate?.editorWebViewEditorState(self)
      let hasFocus = editorState?.hasFocus ?? true
      let hasSelection = editorState?.hasSelection ?? false

      for item in menu.items {
        // Just a hint for the keyboard shortcut, not actually functional
        //
        // WKWebView.showInspector() in WKWebView+Extension.swift does the heavy lifting
        if item.identifier == NSUserInterfaceItemIdentifier.inspectElement {
          item.keyEquivalent = "i"
          item.keyEquivalentModifierMask = [.option, .command]

          if AppDesign.menuIconEvolution {
            item.image = NSImage(systemSymbolName: "ladybug", accessibilityDescription: nil)
          }
        }

        // Disable copy, cut for empty selection (always enable on editor blur)
        if item.tag == WKContextMenuItemTag.copy.rawValue || item.tag == WKContextMenuItemTag.cut.rawValue {
          item.isEnabled = hasSelection || !hasFocus
        }

        // Disable paste for empty pasteboard
        if item.tag == WKContextMenuItemTag.paste.rawValue {
          item.isEnabled = NSPasteboard.general.hasText
        }

        // Disable native items that require text selection (always show on editor blur)
        if let identifier = item.identifier, [
          NSUserInterfaceItemIdentifier.lookUp,
          NSUserInterfaceItemIdentifier.searchWeb,
          NSUserInterfaceItemIdentifier.translate,
          NSUserInterfaceItemIdentifier.shareMenu,
        ].contains(identifier) {
          item.isEnabled = hasSelection || !hasFocus
        }

        // Disable search items that require text selection (always disabled on editor blur)
        if [Localized.Search.findSelection, Localized.Search.selectAllOccurrences].contains(item.title) {
          item.isEnabled = hasSelection && hasFocus
        }

        // Always disable on editor blur
        if item.title == Localized.Toolbar.textFormat || item.tag == WKContextMenuItemTag.searchMenu.rawValue {
          item.isEnabled = hasFocus
        }
      }
    }
  }
}

private extension NSMenuItem {
  func submenuContains(anyOf tags: WKContextMenuItemTag...) -> Bool {
    tags.contains { tag in
      submenu?.items.contains { $0.tag == tag.rawValue } == true
    }
  }
}

private extension NSUserInterfaceItemIdentifier {
  static let lookUp = Self("WKMenuItemIdentifierLookUp")
  static let searchWeb = Self("WKMenuItemIdentifierSearchWeb")
  static let translate = Self("WKMenuItemIdentifierTranslate")
  static let shareMenu = Self("WKMenuItemIdentifierShareMenu")
  static let inspectElement = Self("WKMenuItemIdentifierInspectElement")
}
