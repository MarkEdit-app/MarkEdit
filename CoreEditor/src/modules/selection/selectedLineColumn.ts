import { LineColumnInfo } from './types';

// UTF-16 code-unit distance used as a cheap upper bound for bridge payload size.
const LARGE_PAYLOAD_THRESHOLD = 1000;

export interface LineColumnState {
  // Lazily computes the LineColumnInfo via sliceDoc, call only when needed.
  getInfo: () => LineColumnInfo;
  // True when the bridge payload would be large, computed without sliceDoc.
  isLargePayload: boolean;
}

/**
 * Get the information of the current selected line and column.
 * The result includes a cheap size estimate so callers can decide whether to
 * debounce before calling getInfo(), which performs the actual sliceDoc.
 */
export function selectedLineColumn(): LineColumnState {
  const editor = window.editor;
  const state = editor.state;
  const selection = state.selection.main;
  const line = state.doc.lineAt(selection.head);

  return {
    getInfo: () => ({
      lineNumber: line.number as CodeGen_Int,
      columnText: state.sliceDoc(line.from, selection.head),
      selectionText: state.sliceDoc(selection.from, selection.to),
      selectionRange: {
        anchor: selection.anchor as CodeGen_Int,
        head: selection.head as CodeGen_Int,
      },
    }),
    isLargePayload: (selection.head - line.from) + (selection.to - selection.from) > LARGE_PAYLOAD_THRESHOLD,
  };
}
