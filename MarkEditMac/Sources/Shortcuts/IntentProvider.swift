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
      AppShortcut(intent: CreateNewDocumentIntent(), phrases: []),
      AppShortcut(intent: GetFileContentIntent(), phrases: []),
      AppShortcut(intent: UpdateFileContentIntent(), phrases: []),
    ]
  }
}
