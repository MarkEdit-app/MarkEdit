//
//  IntentProvider.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppIntents

@available(macOS 13.0, *)
struct IntentProvider: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    return [
      AppShortcut(intent: CreateNewDocumentIntent(), phrases: [
        "Create New Document in \(.applicationName)",
      ]),
      AppShortcut(intent: GetFileContentIntent(), phrases: [
        "Get File Content in \(.applicationName)",
      ]),
      AppShortcut(intent: UpdateFileContentIntent(), phrases: [
        "Update File Content in \(.applicationName)",
      ]),
    ]
  }
}
