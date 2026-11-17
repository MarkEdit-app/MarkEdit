//
//  EditorDocument+Closing.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import AppKitExtensions
import MarkEditKit

extension EditorDocument {
  func handleCloseRequest(
    withDelegate delegate: Any,
    shouldClose shouldCloseSelector: Selector?,
    contextInfo: UnsafeMutableRawPointer?
  ) {
    let isNewFile = fileURL == nil
    let confirmsChanges = #selector(confirmsChanges(_:shouldClose:contextInfo:))
    let canHandleConfirmation = (delegate as? NSObject)?.responds(to: confirmsChanges) == true

    let shouldClose: Selector? = {
      if !isNewFile && !isTerminating && closeAlwaysConfirmsChanges && canHandleConfirmation {
        return confirmsChanges
      }

      return shouldCloseSelector
    }()

    let canClose = {
      super.canClose(
        withDelegate: delegate,
        shouldClose: shouldClose,
        contextInfo: contextInfo
      )
    }

    // Closing a new document, force sync to make sure the content is propagated.
    //
    // Don't use `isDraft` here because it's false when closing a document with no files on disk.
    if isNewFile {
      hostViewController?.removeFloatingUIElements()
      return updateContent(saveAction: canClose)
    }

    // Explicitly save the content before closing.
    //
    // Case 1: The content isn't outdated, so auto-saving won't trigger.
    // Case 2: Occasionally, the ".sb" backup file isn't properly cleaned up.
    if (shouldSaveWhenIdle && isOutdated) || (!closeAlwaysConfirmsChanges && isDocumentEdited) {
      return saveContent(completion: canClose)
    }

    // General cases
    Task { @MainActor in
      canClose()
    }
  }
}

// MARK: - Private

private extension EditorDocument {
  var closeAlwaysConfirmsChanges: Bool {
    ApplicationEnvironment.preferences.bool(forKey: NSCloseAlwaysConfirmsChanges)
  }

  @objc func confirmsChanges(
    _ document: EditorDocument,
    shouldClose: Bool,
    contextInfo: UnsafeMutableRawPointer?
  ) {
    guard shouldClose else {
      return // Cancelled
    }

    let performClose: @MainActor @Sendable () -> Void = {
      // isReleasedWhenClosed is not initially set to true to prevent crashes when deleting drafts.
      // However, we need to release the window in the confirmsChanges function;
      // otherwise, it will cause a memory leak.
      document.windowControllers.forEach {
        $0.window?.isReleasedWhenClosed = true
      }

      document.close()
    }

    if document.hasBeenReverted || !document.isDocumentEdited {
      // Reverted or no unsaved changes
      performClose()
    } else {
      // Delay this for two reasons:
      //  1. To make it clear to users that their changes are saved
      //  2. To avoid leftover .sb copies when a document is closed too quickly
      let closeDelayed = {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: performClose)
      }

      // Saved
      document.saveContent(userInitiated: true, completion: closeDelayed)
    }
  }
}
