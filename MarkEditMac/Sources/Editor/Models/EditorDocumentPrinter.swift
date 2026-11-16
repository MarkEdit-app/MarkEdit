//
//  EditorDocumentPrinter.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import MarkEditKit

@MainActor
enum EditorDocumentPrinter {
  static func makeOperation(
    printInfo: NSPrintInfo,
    settings: [NSPrintInfo.AttributeKey: Any],
    showPrintPanel: Bool,
    text: @MainActor () async -> String
  ) async -> NSPrintOperation? {
    guard let info = printInfo.copy() as? NSPrintInfo else {
      Logger.assertFail("NSPrintInfo.copy() must return NSPrintInfo")
      return nil
    }

    // Alignment
    info.isHorizontallyCentered = true
    info.isVerticallyCentered = false
    info.dictionary().addEntries(from: settings)

    // Sizing
    let width = info.paperSize.width - info.leftMargin - info.rightMargin
    let height = info.paperSize.height - info.topMargin - info.bottomMargin
    let frame = CGRect(x: 0, y: 0, width: width, height: height)

    // Rendering
    let textView = NSTextView(frame: frame)
    textView.string = await text()
    textView.sizeToFit()

    let operation = NSPrintOperation(view: textView, printInfo: info)
    operation.showsPrintPanel = showPrintPanel
    return operation
  }
}
