//
//  EditorDocument+Content.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import AppKitExtensions
import MarkEditKit

extension EditorDocument {
  var canUndo: Bool {
    get async {
      if isReadOnlyMode {
        return false
      }

      return (try? await bridge?.history.canUndo()) ?? false
    }
  }

  var canRedo: Bool {
    get async {
      if isReadOnlyMode {
        return false
      }

      return (try? await bridge?.history.canRedo()) ?? false
    }
  }

  var lineEndings: LineEndings? {
    get async {
      try? await bridge?.lineEndings.getLineEndings()
    }
  }

  var needsFormatting: Bool {
    guard !formatCompleted else {
      return false
    }

    return AppPreferences.Assistant.insertFinalNewline || AppPreferences.Assistant.trimTrailingWhitespace
  }

  func waitUntilSaveCompleted(userInitiated: Bool = false, delay: TimeInterval = 0.6) async {
    await withCheckedContinuation { continuation in
      saveContent(userInitiated: userInitiated) {
        continuation.resume()
      }
    }

    // It takes sometime to actually save the document
    await withCheckedContinuation { continuation in
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        continuation.resume()
      }
    }
  }

  func saveContent(sender: Any? = nil, userInitiated: Bool = false, completion: (() -> Void)? = nil) {
    Task { @MainActor in
      let saveAction = {
        super.save(sender)
        completion?()
      }

      // Deferred formatting can remain after the editor text has been synchronized
      if isOutdated || needsFormatting {
        updateContent(userInitiated: userInitiated, saveAction: saveAction)
      } else {
        saveAction()

        if userInitiated {
          markContentClean()
        }
      }
    }
  }

  func updateContent(userInitiated: Bool = false, saveAction: @escaping (() -> Void) = {}) {
    Task { @MainActor in
      await updateContent(userInitiated: userInitiated)
      saveAction()
    }
  }

  func markContentClean() {
    bridge?.history.markContentClean()
  }
}

// MARK: - Private

private extension EditorDocument {
  var bridge: WebModuleBridge? {
    hostViewController?.bridge
  }

  func updateContent(userInitiated: Bool = false) async {
    await formatContent(userInitiated: userInitiated)

    if let editorText = await synchronizeText() {
      writeDebugFile(editorText)
    }

    await updateSuggestedFilename()
    unblockUserInteraction()
    if userInitiated {
      markContentClean()
    }
  }

  func formatContent(userInitiated: Bool) async {
    let insertFinalNewline = AppPreferences.Assistant.insertFinalNewline
    let trimTrailingWhitespace = AppPreferences.Assistant.trimTrailingWhitespace

    if insertFinalNewline || trimTrailingWhitespace {
      formatCompleted = (try? await bridge?.format.formatContent(
        insertFinalNewline: insertFinalNewline,
        trimTrailingWhitespace: trimTrailingWhitespace,
        userInitiated: userInitiated
      )) ?? false
    }
  }

  func writeDebugFile(_ editorText: String) {
    DispatchQueue.global(qos: .utility).async {
      guard !AppRuntimeConfig.disableDebugFiles else {
        return
      }

      let fileData = editorText.toData() ?? Data()
      let directory = AppCustomization.debugDirectory.fileURL
      try? fileData.write(to: directory.appending(path: "last-edited.md"))
    }
  }
}
