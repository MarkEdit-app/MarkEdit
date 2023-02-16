import { EditorView } from '@codemirror/view';
import { editedState, selectionState } from '../../common/store';
import { selectedLineColumn } from '../selection/selectedLineColumn';
import { setShowActiveLineIndicator } from '../../styling/config';

import selectedRange from '../selection/selectedRanges';
import wrapBlock from './wrapBlock';

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

    // Fallback to default behavior
    return false;
  });
}

/**
 * Returns an extension that handles all the editor changes.
 */
export function observeChanges() {
  return EditorView.updateListener.of(update => {
    // We only notify changes when the editor is not dirty (all changes are saved)
    if (update.docChanged && !editedState.isDirty) {
      // It would be great if we could also provide the updated text here,
      // but it's time-consuming for large payload,
      // we want to be responsive for every key stroke.
      window.nativeModules.core.notifyTextDidChange();
      editedState.isDirty = true;
    }

    if (update.selectionSet) {
      const lineColumn = selectedLineColumn();
      window.nativeModules.core.notifySelectionDidChange({ lineColumn });

      const hasSelection = selectedRange().some(range => !range.empty);
      const updateActiveLine = selectionState.hasSelection !== hasSelection;
      selectionState.hasSelection = hasSelection;

      // Clear active line background when there's selection,
      // it makes the selection easier to read.
      if (updateActiveLine) {
        setShowActiveLineIndicator(!hasSelection && window.config.showActiveLineIndicator);
      }
    }
  });
}
