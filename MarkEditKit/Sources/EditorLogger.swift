//
//  EditorLogger.swift
//
//  Created by cyan on 12/22/22.
//

import Foundation
import os.log

public enum Logger {
  public static func log(_ level: OSLogType, _ message: @autoclosure @escaping () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
    var file: String = "\(file)"
    if let url = URL(string: file) {
      file = url.lastPathComponent
    }

    os_logger.log(level: level, "\(file):\(line), \(function) -> \(message())")
  }

  public static func assertFail(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    assertionFailure(message(), file: file, line: line)
  }

  public static func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    if !condition() {
      assertionFailure(message(), file: file, line: line)
    }
  }
}

private let os_logger = os.Logger()
