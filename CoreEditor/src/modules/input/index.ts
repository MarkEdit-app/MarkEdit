import { EditorView } from '@codemirror/view';
import { InvisiblesBehavior } from '../../config';
import { editingState } from '../../common/store';
import { selectedLineColumn } from '../selection/selectedLineColumn';
import { setInvisiblesBehavior } from '../config';
import { startCompletion, isPanelVisible } from '../completion';
import { isContentDirty } from '../history';
import { tokenizePosition } from '../tokenizer';
import { scrollCaretToVisible, scrollToSelection } from '../../modules/selection';
import { setShowActiveLineIndicator } from '../../styling/config';
import { renderWhitespaceBeforeCaret } from '../../styling/nodes/invisible';

import selectedRange from '../selection/selectedRanges';
import wrapBlock from './wrapBlock';

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
      update(_update) { /* no-op */},
    };
  });
}

/**
 * Give us an opportunity to intercept user inputs.
 *
 * @returns True to ignore the default behavior
 */
export function interceptInputs() {
  const marksToWrap = ['`', '*', '_', '~', '$'];

  return EditorView.inputHandler.of((editor, _from, _to, insert) => {
    // E.g., wrap "selection" as "*selection*"
    if (marksToWrap.includes(insert)) {
      return wrapBlock(insert, editor);
    }

    if ((window.config.suggestWhileTyping || isPanelVisible()) && insert.trim().length > 0) {
      // Typing suggestions for non-space insertions
      startCompletion({ afterDelay: 300 });
    } else if (isPanelVisible()) {
      // Cancel the completion for whitespace insertions
      window.nativeModules.completion.cancelCompletion();
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
    if (editingState.isIdle && window.editor.state.doc.length === 0) {
      return;
    }

    if (update.docChanged) {
      // It would be great if we could also provide the updated text here,
      // but it's time-consuming for large payload,
      // we want to be responsive for every key stroke.
      window.nativeModules.core.notifyTextDidChange({ isDirty: isContentDirty() });

      // Make sure the main selection is always centered for typewriter mode
      if (window.config.typewriterMode) {
        scrollToSelection('center');
      } else {
        // We need this because we have different line height for headings,
        // CodeMirror doesn't by default fix the offset issue.
        scrollCaretToVisible();
      }
    }

    if (update.selectionSet) {
      const lineColumn = selectedLineColumn();
      window.nativeModules.core.notifySelectionDidChange({ lineColumn, contentEdited: update.docChanged });

      const hasSelection = selectedRange().some(range => !range.empty);
      const updateActiveLine = editingState.hasSelection !== hasSelection;
      editingState.hasSelection = hasSelection;

      if (updateActiveLine) {
        // Update invisible behavior as selection changed
        const invisiblesBehavior = window.config.invisiblesBehavior;
        if (invisiblesBehavior === InvisiblesBehavior.selection) {
          setInvisiblesBehavior(invisiblesBehavior);
        }

        // Clear active line background when there's selection,
        // it makes the selection easier to read.
        setShowActiveLineIndicator(!hasSelection && window.config.showActiveLineIndicator);
      }

      // Render the special invisible before the main caret
      renderWhitespaceBeforeCaret();
    }
  });
}
