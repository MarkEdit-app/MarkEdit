import { EditorSelection } from '@codemirror/state';
import { getClientRect } from '../../common/utils';

export function setActive(isActive: boolean) {
  storage.isActive = isActive;

  if (isActive) {
    ensureSelectionRect();
  }
}

export function isActive() {
  return storage.isActive;
}

export function getSelectionRect() {
  ensureSelectionRect();

  const selection = window.getSelection();
  if (selection === null) {
    return undefined;
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
} = {
  isActive: false,
};