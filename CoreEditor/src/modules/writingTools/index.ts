import { EditorSelection, SelectionRange, Transaction } from '@codemirror/state';
import { getClientRect } from '../../common/utils';

export function setActive(isActive: boolean, requestedTool: number) {
  storage.isActive = isActive;
  storage.requestedTool = requestedTool;

  if (isActive) {
    ensureSelectionRect();
    storage.selectedRange = window.editor.state.selection.main;
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

  // Extend the selection to make sure all affected lines are fully selected
  const { from } = doc.lineAt(selection.from);
  const { to } = doc.lineAt(selection.to);
  editor.dispatch({ selection: EditorSelection.range(from, to) });
}

export function scheduleWritingToolsUpdate(transaction: Transaction) {
  if (storage.isActive && transaction.isUserEvent('input.type')) {
    setTimeout(forceWritingToolsUpdate, 100);
  }
}

function forceWritingToolsUpdate() {
  const { selection, from, to } = affectedSelectionRange();
  if (selection.empty || !storage.isActive) {
    // [macOS 15] WritingTools cancels the selection, reselect it
    return window.editor.dispatch({
      selection: EditorSelection.range(from, to),
      userEvent: 'forceWritingToolsSelect',
    });
  }
  
  // [macOS 15] WritingTools (except proofread) cannot stop and duplicate trailing content will be generated
  if (storage.requestedTool !== 1) {
    const text = window.editor.state.sliceDoc(selection.from, selection.to);
    window.editor.dispatch({
      changes: { from, to, insert: text },
      selection: EditorSelection.range(from, from + text.length),
      userEvent: 'forceWritingToolsInsert',
    });
  }
}

function affectedSelectionRange() {
  const state = window.editor.state;
  const selection = state.selection.main;

  // The start position of the initial range and the end position of the last line
  const from = state.doc.lineAt(storage.selectedRange.from).from;
  const to = state.doc.lineAt(selection.to).to;

  return { selection, from, to };
}

const storage: {
  isActive: boolean;
  requestedTool: number;
  selectedRange: SelectionRange;
} = {
  isActive: false,
  requestedTool: 0,
  selectedRange: EditorSelection.range(0, 0),
};
