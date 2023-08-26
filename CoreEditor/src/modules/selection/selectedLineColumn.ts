import { LineColumnInfo } from './types';

/**
 * Get the information of the current selected line and column.
 */
export function selectedLineColumn(): LineColumnInfo {
  const editor = window.editor;
  const state = editor.state;
  const selection = state.selection.main;
  const line = state.doc.lineAt(selection.head);

  return {
    lineNumber: line.number as CodeGen_Int,
    columnText: state.sliceDoc(line.from, selection.head),
    selectionText: state.sliceDoc(selection.from, selection.to),
  };
}
