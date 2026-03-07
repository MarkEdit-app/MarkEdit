//
//  MarkEditWritingTools.swift
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
enum MarkEditWritingTools {
  static var requestedTool: WritingTool {
    for window in NSApp.windows {
      guard let controller = window.contentViewController,
            controller.className == "WTWritingToolsViewController" else {
        continue
      }

      // WTWritingToolsConfiguration
      let configSelector = sel_getUid("writingToolsConfiguration")
      let target: NSObject = {
        guard controller.responds(to: configSelector) else {
          NSLog("Missing method selector for: %@, %@", "\(controller)", "writingToolsConfiguration")
          return controller
        }

        let impl = unsafeBitCast(
          controller.method(for: configSelector),
          to: (@convention(c) (NSObject, Selector) -> NSObject?).self
        )
        return impl(controller, configSelector) ?? controller
      }()

      let toolSelector = sel_getUid("requestedTool")
      guard target.responds(to: toolSelector) else {
        NSLog("Missing method selector for: %@, %@", "\(target)", "requestedTool")
        return .panel
      }

      let impl = unsafeBitCast(
        target.method(for: toolSelector),
        to: (@convention(c) (NSObject, Selector) -> Int).self
      )

      return WritingTool(rawValue: impl(target, toolSelector)) ?? .panel
    }

    return .panel
  }

  static var affordanceIcon: NSImage? {
    let configuration = NSImage.SymbolConfiguration(pointSize: 12.5, weight: .medium)
    let symbolImage = NSImage(systemSymbolName: "apple.writing.tools", accessibilityDescription: nil)
      ?? NSImage(systemSymbolName: "_gm", accessibilityDescription: nil)

    if let symbolImage {
      return symbolImage.withSymbolConfiguration(configuration)
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
private extension MarkEditWritingTools {
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

    let impl = unsafeBitCast(
      method_getImplementation(classMethod),
      to: (@convention(c) (AnyObject, Selector) -> NSObject?).self
    )
    let instance = impl(cls as AnyObject, selector)

    assert(instance != nil, "Failed to get WTWritingTools instance")
    return instance
  }
}
