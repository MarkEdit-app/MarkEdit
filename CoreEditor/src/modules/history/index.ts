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
