import { EditorSelection } from '@codemirror/state';
import { getClientRect } from '../../common/utils';

export function setActive(isActive: boolean, reselect: boolean) {
  storage.isActive = isActive;

  if (storage.selectionKeeper !== undefined) {
    clearInterval(storage.selectionKeeper);
    storage.selectionKeeper = undefined;
  }

  if (isActive && reselect) {
    ensureSelectionRect();

    // Apple Writing Tools sometimes randomly selects portion of the current line,
    // Unfortunately, there is no event we can observe to detect that behavior.
    //
    // Here we periodically reselect the current line to prevent that.
    storage.selectionKeeper = setInterval(() => {
      const state = window.editor.state;
      const selection = state.selection.main;
      const { from } = state.doc.lineAt(selection.from);
      const { to } = state.doc.lineAt(selection.to);

      if (selection.from !== from || selection.to !== to) {
        window.editor.dispatch({
          selection: EditorSelection.range(from, to),
        });
      }
    }, 500);
  }
}

export function isActive() {
  return storage.isActive;
}

export function getSelectionRect(reselect: boolean) {
  if (reselect) {
    ensureSelectionRect();
  }

  const selection = window.getSelection();
  if (selection === null) {
    return undefined;
  }

  const state = window.editor.state;
  const line = state.doc.lineAt(state.selection.main.from);

  // getBoundingClientRect is returning invalid rect for empty lines
  if (line.from === line.to) {
    const coords = window.editor.coordsAtPos(line.from);
    if (coords !== null) {
      return getClientRect(coords);
    }
  }

  const range = selection.getRangeAt(0);
  return getClientRect(range.getBoundingClientRect());
}

export function ensureSelectionRect() {
  const editor = window.editor;
  const selection = editor.state.selection.main;
  const doc =  editor.state.doc;

  const { from } = doc.lineAt(selection.from);
  const { to } = doc.lineAt(selection.to);

  if (from === to) {
    // Extend the selection to select the entire document
    editor.dispatch({ selection: EditorSelection.range(0, editor.state.doc.length) });
  } else {
    // Extend the selection to make sure all affected lines are fully selected
    editor.dispatch({ selection: EditorSelection.range(from, to) });
  }
}

const storage: {
  isActive: boolean;
  selectionKeeper: ReturnType<typeof setInterval> | undefined;
} = {
  isActive: false,
  selectionKeeper: undefined,
};
