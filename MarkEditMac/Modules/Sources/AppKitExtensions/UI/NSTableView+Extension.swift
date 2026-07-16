//
//  NSTableView+Extension.swift
//
//  Created by cyan on 7/16/26.
//

import AppKit

public extension NSTableView {
  /// Runs row mutations inside a single `beginUpdates`/`endUpdates` batch.
  func performBatchUpdates(_ updates: () -> Void) {
    beginUpdates()
    updates()
    endUpdates()
  }

  /// Animates the row-level difference between two snapshots identified by `id`.
  ///
  /// Only insertions and removals are applied; surviving rows keep their existing views.
  /// A moved row appears as a remove plus insert, since survivors can't be reordered in one batch.
  /// Ids are assumed unique within each snapshot, per the `Identifiable` contract.
  func animateRows<Element: Identifiable>(
    from old: [Element],
    to new: [Element],
    insertAnimation: AnimationOptions = .effectGap,
    removeAnimation: AnimationOptions = [.effectFade, .slideUp]
  ) {
    var removed = IndexSet()
    var inserted = IndexSet()

    for change in new.map(\.id).difference(from: old.map(\.id)) {
      switch change {
      case let .remove(offset, _, _):
        removed.insert(offset)
      case let .insert(offset, _, _):
        inserted.insert(offset)
      }
    }

    performBatchUpdates {
      if !removed.isEmpty {
        removeRows(at: removed, withAnimation: removeAnimation)
      }

      if !inserted.isEmpty {
        insertRows(at: inserted, withAnimation: insertAnimation)
      }
    }
  }
}
