import { ChangeSet } from '@codemirror/state';
import { historyField, undo as undoCommand, redo as redoCommand, undoDepth, redoDepth } from '@codemirror/commands';

// Weirdly, CodeMirror doesn't expose HistoryState as a public interface,
// define it here and leverage tests to ensure its existence.
interface HistoryState {
  done?: HistoryEvent[];
  undone?: HistoryEvent[];
}

interface HistoryEvent {
  changes?: ChangeSet;
}

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

export function clearHistory() {
  try {
    const editor = window.editor;
    const history = editor.state.field(historyField) as HistoryState;
    history.done = [];
    history.undone = [];
  } catch (error) {
    console.error(error);
  }
}
