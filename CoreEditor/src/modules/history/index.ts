import { ViewUpdate } from '@codemirror/view';
import { Transaction } from '@codemirror/state';
import { undo as undoCommand, redo as redoCommand, undoDepth, redoDepth } from '@codemirror/commands';

/**
 * In the client codebase, we need to bind the native undo to this function.
 */
export function undo() {
  undoCommand(window.editor);
}

/**
 * In the client codebase, we need to bind the native redo to this function.
 */
export function redo() {
  redoCommand(window.editor);
}

export function canUndo() {
  return undoDepth(window.editor.state) > 0;
}

export function canRedo() {
  return redoDepth(window.editor.state) > 0;
}

export function markContentClean() {
  // This function is called when the user saves the document, we save the current undo depth,
  // as a result, the content is treated as "clean".
  //
  // When text changes, we use these values to determine the "isDirty" state.
  storage.savedUndoDepth = undoDepth(window.editor.state);
  storage.explictlyMoved = true;
}

export function isContentDirty() {
  // The content is "dirty" when the latest change was not directly moving the history, or the current undo depth is not the same as the saved depth,
  // i.e., there're unsaved changes.
  //
  // This also means that the content is "clean" when we explicitly move the history cursor at the saved depth.
  return !storage.explictlyMoved || (storage.savedUndoDepth !== undoDepth(window.editor.state));
}

export function setHistoryExplictlyMoved(update: ViewUpdate) {
  storage.explictlyMoved = update.transactions.some(transaction => {
    const userEvent = transaction.annotation(Transaction.userEvent);
    return userEvent === 'undo' || userEvent === 'redo';
  });
}

const storage: {
  savedUndoDepth: number;
  explictlyMoved: boolean;
} = {
  savedUndoDepth: 0,
  explictlyMoved: true, // Treat the initial state as "explicitly saved"
};
