//
//  AppWritingTools.swift
//  MarkEditMac
//
//  Created by cyan on 8/14/24.
//

import AppKit
import AppKitExtensions
import MarkEditKit

enum AppWritingTools {
  // Source/WebKit/Platform/spi/Cocoa/Modules/WritingTools_SPI/WritingToolsSPI.h
  enum Tool: Int {
    case index = 0

    case proofread = 1
    case rewrite = 2
    case rewriteProofread = 3

    case rewriteFriendly = 11
    case rewriteProfessional = 12
    case rewriteConcise = 13
    case rewriteOpenEnded = 19

    case transformSummarize = 21
    case transformKeyPoints = 22
    case transformList = 23
    case transformTable = 24

    case smartReply = 101

    case compose = 201
  }

  static var requestedTool: Tool {
    guard let controller = NSApp.windows
      .compactMap(\.contentViewController)
      .first(where: { $0.className == "WTWritingToolsViewController" }) else {
      return .index
    }

    // WTWritingToolsConfiguration
    guard let target = invokeObject(controller, selector: "writingToolsConfiguration") else {
      return .index
    }

    return .init(rawValue: invokeInt(target, selector: "requestedTool")) ?? .index
  }

  static var affordanceIcon: NSImage? {
    let configuration = NSImage.SymbolConfiguration(
      pointSize: 12.5,
      weight: .medium
    )

    for symbolName in ["apple.writing.tools", "_gm"] {
      if let symbolImage = NSImage(systemSymbolName: symbolName) {
        return symbolImage.withSymbolConfiguration(configuration)
      }
    }

    guard let affordanceClass = NSClassFromString("WTAffordanceView") as? NSView.Type else {
      Logger.assertFail("Missing WTAffordanceView class")
      return nil
    }

    let affordanceView = affordanceClass.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    for case let imageView as NSImageView in affordanceView.subviews {
      return imageView.image?.withSymbolConfiguration(configuration)
    }

    Logger.assertFail("Failed to retrieve affordance icon")
    return nil
  }

  static func shouldReselect(withItem item: Any?) -> Bool {
    guard let menuItem = item as? NSMenuItem else {
      return false
    }

    return shouldReselect(with: .init(rawValue: menuItem.tag) ?? .index)
  }

  static func shouldReselect(with tool: Tool) -> Bool {
    // These tools can start without text selections
    tool != .smartReply && tool != .compose
  }

  @available(macOS 27.0, *)
  static func ensureWritingTools(menu: NSMenu, target: AnyObject) {
    guard !(menu.items.contains { $0.identifier == .writingTools }) else {
      return
    }

    guard target.responds(to: Self.mainMenuAction) else {
      Logger.assertFail("\(target) does not respond to \(Self.mainMenuAction)")
      return
    }

    let item = NSMenuItem(
      title: Localized.WritingTools.menuItemTitle,
      action: Self.mainMenuAction,
      keyEquivalent: ""
    )

    let index: Int = {
      // Before "Spelling and Grammar"
      if let target = (menu.items.first { $0.identifier == .spellingMenu }) {
        return menu.index(of: target)
      }

      // Or as the first one
      return 0
    }()

    item.identifier = .writingTools
    item.target = target
    menu.items.insert(item, at: index)
    menu.items.insert(.separator(), at: index + 1)
  }
}

// MARK: - Private

private extension AppWritingTools {
  /// The action that opens `Writing Tools`.
  ///
  /// https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebViewPrivate.h
  static let mainMenuAction = sel_getUid("_showWritingTools")

  /// Invokes a selector on a target and returns the result as `NSObject?`.
  static func invokeObject(_ target: NSObject, selector name: String) -> NSObject? {
    guard let (sel, impl) = invocation(of: target, selector: name) else {
      return nil
    }

    let fn = unsafeBitCast(impl, to: (@convention(c) (NSObject, Selector) -> NSObject?).self)
    return fn(target, sel)
  }

  /// Invokes a selector on a target and returns the result as `Int`.
  static func invokeInt(_ target: NSObject, selector name: String) -> Int {
    guard let (sel, impl) = invocation(of: target, selector: name) else {
      return 0
    }

    let fn = unsafeBitCast(impl, to: (@convention(c) (NSObject, Selector) -> Int).self)
    return fn(target, sel)
  }

  static func invocation(of target: NSObject, selector name: String) -> (Selector, IMP)? {
    let selector = sel_getUid(name)
    guard target.responds(to: selector) else {
      Logger.assertFail("Missing method selector for: \(target), \(name)")
      return nil
    }

    return (selector, target.method(for: selector))
  }
}

private extension NSUserInterfaceItemIdentifier {
  static let writingTools = Self("WKMenuItemIdentifierWritingTools")
  static let spellingMenu = Self("WKMenuItemIdentifierSpellingMenu")
}
