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
      AppShortcut(
        intent: CreateNewDocumentIntent(),
        phrases: [
          "Create New Document in \(.applicationName)",
        ],
        shortTitle: "Create New Document",
        systemImageName: "plus.square"
      ),
      AppShortcut(
        intent: EvaluateJavaScriptIntent(),
        phrases: [
          "Evaluate JavaScript in \(.applicationName)",
        ],
        shortTitle: "Evaluate JavaScript",
        systemImageName: "curlybraces.square"
      ),
      AppShortcut(
        intent: GetFileContentIntent(),
        phrases: [
          "Get File Content in \(.applicationName)",
        ],
        shortTitle: "Get File Content",
        systemImageName: "doc.plaintext"
      ),
      AppShortcut(
        intent: UpdateFileContentIntent(),
        phrases: [
          "Update File Content in \(.applicationName)",
        ],
        shortTitle: "Update File Content",
        systemImageName: "character.textbox"
      ),
    ]
  }
}
