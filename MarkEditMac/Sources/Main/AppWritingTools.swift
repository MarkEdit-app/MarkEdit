//
//  AppWritingTools.swift
//  MarkEditMac
//
//  Created by cyan on 8/14/24.
//

import AppKit

@available(macOS 15.1, *)
enum WritingTool: Int {
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

@available(macOS 15.1, *)
enum AppWritingTools {
  static var requestedTool: WritingTool {
    guard let controller = NSApp.windows
      .compactMap(\.contentViewController)
      .first(where: { $0.className == "WTWritingToolsViewController" }) else {
      return .panel
    }

    // WTWritingToolsConfiguration
    let target: NSObject = invoke(controller, selector: "writingToolsConfiguration", fallback: nil) ?? controller
    return WritingTool(rawValue: invoke(target, selector: "requestedTool", fallback: 0)) ?? .panel
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
      assertionFailure("Missing WTAffordanceView class")
      return nil
    }

    let affordanceView = affordanceClass.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    for case let imageView as NSImageView in affordanceView.subviews {
      return imageView.image?.withSymbolConfiguration(configuration)
    }

    assertionFailure("Failed to retrieve affordance icon")
    return nil
  }

  static func shouldReselect(withItem item: Any?) -> Bool {
    guard let menuItem = item as? NSMenuItem else {
      return false
    }

    return shouldReselect(with: WritingTool(rawValue: menuItem.tag) ?? .panel)
  }

  static func shouldReselect(with tool: WritingTool) -> Bool {
    // Compose mode can start without text selections
    tool != .compose
  }
}

// MARK: - Private

@available(macOS 15.1, *)
private extension AppWritingTools {
  /// Invokes a selector on a target and returns the result cast to the inferred type.
  static func invoke<Result>(_ target: NSObject, selector name: String, fallback: Result) -> Result {
    let selector = sel_getUid(name)
    guard target.responds(to: selector) else {
      NSLog("Missing method selector for: %@, %@", "\(target)", name)
      return fallback
    }

    return unsafeBitCast(
      target.method(for: selector),
      to: (@convention(c) (NSObject, Selector) -> Result).self
    )(target, selector)
  }

  static var writingToolsInstance: NSObject? {
    guard let cls = NSClassFromString("WTWritingTools") else {
      assertionFailure("Failed to get WTWritingTools class")
      return nil
    }

    let selector = sel_getUid("sharedInstance")
    guard let classMethod = class_getClassMethod(cls, selector) else {
      NSLog("Missing method selector for: WTWritingTools, sharedInstance")
      return nil
    }

    let instance = unsafeBitCast(
      method_getImplementation(classMethod),
      to: (@convention(c) (AnyObject, Selector) -> NSObject?).self
    )(cls as AnyObject, selector)

    assert(instance != nil, "Failed to get WTWritingTools instance")
    return instance
  }
}
