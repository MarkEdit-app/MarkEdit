//
//  IntentProvider.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppIntents

struct IntentProvider: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    return [
      AppShortcut(intent: CreateNewDocumentIntent(), phrases: [
        "Create New Document in \(.applicationName)",
      ]),
      AppShortcut(intent: CreateNewDocumentIntent(), phrases: [
        "Evaluate JavaScript in \(.applicationName)",
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
