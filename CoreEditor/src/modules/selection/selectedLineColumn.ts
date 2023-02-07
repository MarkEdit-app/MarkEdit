import { LineColumnInfo } from './types';

/**
 * Get the information of the current selected line and column.
 */
export function selectedLineColumn(): LineColumnInfo {
  const editor = window.editor;
  const state = editor.state;
  const selection = editor.state.selection.main;
  const line = state.doc.lineAt(selection.head);
  const column = selection.head - line.from + 1;

  return {
    line: line.number as CodeGen_Int,
    column: column as CodeGen_Int,
    length: (selection.to - selection.from) as CodeGen_Int,
  };
}
