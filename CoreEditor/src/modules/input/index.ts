import { EditorView } from '@codemirror/view';
import { EditorSelection, Transaction } from '@codemirror/state';
import { foldEffect, unfoldEffect } from '@codemirror/language';
import { startCompletion as startTooltipCompletion } from '@codemirror/autocomplete';
import { globalState, editingState } from '../../common/store';
import { clearSyntaxSelections } from '../commands';
import { startCompletion, isPanelVisible } from '../completion';
import { hasRecentKeyPress } from '../events';
import { isContentDirty, setHistoryExplictlyMoved } from '../history';
import { adjustActiveLineGutter, adjustGutterPositions } from '../lines';
import { tokenizePosition } from '../tokenizer';
import { refreshEditFocus, scrollCaretToVisible, scrollToSelection, selectedLineColumn, updateActiveLine } from '../../modules/selection';

import hasSelection from '../selection/hasSelection';
import redrawSelectionLayer from '../selection/redrawSelectionLayer';
import wrapBlock from './wrapBlock';
import insertCodeBlock from './insertCodeBlock';

export function filterTransaction(transaction: Transaction) {
  // Return nothing for read-only mode
  if (window.config.readOnlyMode && transaction.docChanged) {
    return [];
  }

  // Prevent the browser from selecting line breaks at the end of lines
  if (!transaction.docChanged && transaction.newSelection.ranges.length === 1 && (Date.now() - globalState.contextMenuOpenTime < 500)) {
    const { state } = window.editor;
    const { from, to } = transaction.newSelection.main;
    if (state.sliceDoc(from, to) === state.lineBreak) {
      return state.update({
        changes: transaction.changes,
        effects: transaction.effects,
        selection: EditorSelection.cursor(from),
      });
    }
  }

  return transaction;
}

/**
 * Tokenize words at the click position, especially useful for languages like Chinese and Japanese.
 */
export function wordTokenizer() {
  return EditorView.mouseSelectionStyle.of((editor, event) => {
    if (tokenizePosition(event) === null) {
      return null;
    }

    // There isn't an async way to get selection in CodeMirror,
    // we simply just leave the selection as is and handle the updates in a "dblclick" event handler.
    return {
      get(_event, _extend, _multiple) { return editor.state.selection; },
      update(_update) { /* no-op */ },
    };
  });
}

/**
 * Give us an opportunity to intercept user inputs.
 *
 * @returns True to ignore the default behavior
 */
export function interceptInputs() {
  const marksToWrap = ['*', '_', '~', '$'];

  return EditorView.inputHandler.of((editor, from, to, insert) => {
    // Enable auto character pairs only after composition ends,
    // some characters act as marked text in certain languages, e.g., typing '`' followed by 'a' to input 'à'.
    const autoCharacterPairs = window.config.autoCharacterPairs && editingState.compositionEnded;

    // E.g., wrap "selection" as "*selection*"
    if (autoCharacterPairs && marksToWrap.includes(insert)) {
      return wrapBlock(insert, editor);
    }

    // Insert triple backticks to create a code block
    if (autoCharacterPairs && insert === '`') {
      return insertCodeBlock(editor);
    }

    if ((window.config.suggestWhileTyping || isPanelVisible()) && insert.trim().length > 0) {
      // Typing suggestions for non-space insertions
      startCompletion({ afterDelay: 300 });
    } else if (isPanelVisible()) {
      // Cancel the completion for whitespace insertions
      window.nativeModules.completion.cancelCompletion();
    }

    // Try tooltip completion if selection is replaced
    if (from !== to && insert.length > 0) {
      setTimeout(() => startTooltipCompletion(editor), 200);
    }

    // Fallback to default behavior
    return false;
  });
}

/**
 * Returns an extension that handles all the editor changes.
 */
export function observeChanges() {
  return EditorView.updateListener.of(update => {
    // Ignore all events when the editor is idle
    if (editingState.isIdle && update.state.doc.length === 0) {
      return;
    }

    if (update.docChanged) {
      // This should be called before updating the native view
      setHistoryExplictlyMoved(update);

      if (!update.transactions.some(tr => tr.annotation(Transaction.userEvent) === '@none')) {
        // We need this because we have different line height for headings,
        // CodeMirror doesn't by default fix the offset issue.
        scrollCaretToVisible();

        // Make sure the main selection is always centered for typewriter mode
        if (window.config.typewriterMode) {
          scrollToSelection('center');
        }
      }

      // Content is updated periodically
      if (storage.contentUpdater !== undefined) {
        clearTimeout(storage.contentUpdater);
      }

      storage.contentUpdater = setTimeout(() => {
        window.nativeModules.core.notifyEditorDidBecomeIdle();
      }, 1500);
    }

    // CodeMirror doesn't mark `selectionSet` true when selection is cut or replaced,
    // always check `docChanged` too.
    if (update.selectionSet || update.docChanged) {
      const newHasSelection = hasSelection();
      const selectionStateChanged = editingState.hasSelection !== newHasSelection;
      editingState.hasSelection = newHasSelection;

      // We don't update active lines when composition is still ongoing.
      //
      // Instead, we will make an extra update after composition ended.
      if (editingState.compositionEnded && selectionStateChanged) {
        updateActiveLine(newHasSelection);
      }

      // Work around a WebKit bug where selection layer is not updated
      if (!newHasSelection && selectionStateChanged) {
        redrawSelectionLayer();
      }

      // Handle native updates.
      //
      // It would be great if we could also provide the updated text here,
      // but it's time-consuming for large payload,
      // we want to be responsive for every key stroke.
      window.nativeModules.core.notifyViewDidUpdate({
        contentEdited: update.docChanged,
        compositionEnded: editingState.compositionEnded,
        isDirty: isContentDirty(),
        selectedLineColumn: selectedLineColumn(),
      });

      // Fragile but simple method to clear the syntax-aware selection stack
      clearSyntaxSelections();
    }

    if (window.config.showLineNumbers) {
      // Gutter update triggered by geometry or viewport changes (delayed)
      if (update.geometryChanged || update.viewportChanged) {
        if (storage.gutterUpdater !== undefined) {
          clearTimeout(storage.gutterUpdater);
        }

        if (editingState.compositionEnded && update.docChanged) {
          // To handle a case where line number rects are not correctly updated
          update.view.requestMeasure();

          requestAnimationFrame(() => {
            // To handle a case where the active line doesn't report correct height, possibly due to text predictions
            adjustActiveLineGutter();

            // Content changed without key press, could be a system event like accepting inline predictions
            if (!hasRecentKeyPress()) {
              refreshEditFocus(); // Caret can be misplaced accepting inline predictions
            }
          });
        }

        const caretOffsetY = storage.caretOffsetY;
        storage.caretOffsetY = update.view.coordsAtPos(update.state.selection.main.to)?.bottom;

        if (caretOffsetY !== undefined && caretOffsetY !== storage.caretOffsetY) {
          // Re-layout immediately when the y-axis of the caret position changes
          adjustGutterPositions();
        } else {
          // Otherwise, the update is throttled with a small delay
          storage.gutterUpdater = setTimeout(adjustGutterPositions, 15);
        }
      }

      // Gutter update triggered by fold or unfold actions (immediately)
      if (update.transactions.some(tr => tr.effects.some(e => e.is(foldEffect) || e.is(unfoldEffect)))) {
        adjustGutterPositions();

        if (globalState.gutterHovered) {
          adjustGutterPositions('gutterHover');
        }
      }
    }
  });
}

const storage: {
  caretOffsetY: number | undefined;
  gutterUpdater: ReturnType<typeof setTimeout> | undefined;
  contentUpdater: ReturnType<typeof setTimeout> | undefined;
} = {
  caretOffsetY: undefined,
  gutterUpdater: undefined,
  contentUpdater: undefined,
};
