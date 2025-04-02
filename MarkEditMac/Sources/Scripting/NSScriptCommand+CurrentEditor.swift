//
//  NSScriptCommand+Scripting.swift
//  MarkEdit
//
//  Created by Steven Kaplan on 4/2/25.
//

extension NSScriptCommand {
  /// Returns the current active editor, or nil if not applicable.
  @MainActor var currentEditor: EditorViewController? {
    let orderedControllers = EditorReusePool.shared.viewControllers().sorted {
      let lhs = $0.view.window?.orderedIndex ?? .max
      let rhs = $1.view.window?.orderedIndex ?? .max
      return lhs < rhs
    }

    return orderedControllers.first { $0.view.window != nil } ?? (NSApp as? Application)?.currentEditor
  }
}
