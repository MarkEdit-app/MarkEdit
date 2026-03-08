//
//  AppWritingTools.swift
//  MarkEditMac
//
//  Created by cyan on 8/14/24.
//

import AppKit
import MarkEditKit

@available(macOS 15.1, *)
enum AppWritingTools {
  enum Tool: Int {
    case panel = 0
    case proofread = 1
    case rewrite = 2
    case makeFriendly = 11
    case makeProfessional = 12
    case makeConcise = 13
    case summarize = 21
    case createKeyPoints = 22
    case makeList = 23
    case makeTable = 24
    case compose = 201
  }

  static var requestedTool: Tool {
    guard let controller = NSApp.windows
      .compactMap(\.contentViewController)
      .first(where: { $0.className == "WTWritingToolsViewController" }) else {
      return .panel
    }

    // WTWritingToolsConfiguration
    guard let target = invokeObject(controller, selector: "writingToolsConfiguration") else {
      return .panel
    }

    return .init(rawValue: invokeInt(target, selector: "requestedTool")) ?? .panel
  }

  static var affordanceIcon: NSImage? {
    let configuration = NSImage.SymbolConfiguration(
      pointSize: 12.5,
      weight: .medium
    )

    for symbolName in ["apple.writing.tools", "_gm"] {
      if let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
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

    return shouldReselect(with: .init(rawValue: menuItem.tag) ?? .panel)
  }

  static func shouldReselect(with tool: Tool) -> Bool {
    // Compose mode can start without text selections
    tool != .compose
  }
}

// MARK: - Private

@available(macOS 15.1, *)
private extension AppWritingTools {
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
