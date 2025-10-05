//
//  AppExceptionCatcher.swift
//  MarkEdit
//
//  Created by cyan on 10/5/25.
//

import AppKit

enum AppExceptionCatcher {
  static func install() {
    NSSetUncaughtExceptionHandler(handleException)
  }
}

private func handleException(_ exception: NSException) {
  let headers = [
    "Exception: \(exception.name.rawValue)",
    "Reason: \(exception.reason ?? "")",
    "UserInfo: \(exception.userInfo ?? [:])",
    "Date: \(Date.now)\n",
  ]

  let symbols = exception.callStackSymbols.prefix(128)
  let data = (headers + symbols).joined(separator: "\n").data(using: .utf8) ?? Data()

  let url = AppCustomization.debugDirectory.fileURL.appending(path: "last-crash.log")
  let fd = open(url.path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)

  if fd != -1 {
    _ = data.withUnsafeBytes { ptr in
      write(fd, ptr.baseAddress, data.count)
    }

    close(fd)
  }
}
