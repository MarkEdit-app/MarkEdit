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
  // When text changes, we use this value to calculate the "isDirty" state.
  storage.savedUndoDepth = undoDepth(window.editor.state);
}

export function isContentDirty() {
  // The content is "dirty" when the current undo depth is not the same as the saved depth,
  // i.e., there're unsaved changes.
  return storage.savedUndoDepth !== undoDepth(window.editor.state);
}

const storage: {
  savedUndoDepth: number;
} = {
  savedUndoDepth: 0,
};
