import { EditorView } from '@codemirror/view';
import { EditorSelection, Line, SelectionRange } from '@codemirror/state';
import { getClientRect } from '../../common/utils';

import { InvisiblesBehavior } from '../../config';
import { setInvisiblesBehavior } from '../config';
import { setShowActiveLineIndicator } from '../../styling/config';

import selectedRanges from './selectedRanges';
import selectWholeLineAt from './selectWholeLineAt';
import searchMatchPosition from './searchMatchPosition';

/**
 * Reverse ranges for multi-selection to keep indices correct when updating.
 */
export function reversedRanges() {
  return selectedRanges().reverse();
}

/**
 * Reverse ranges for multi-selection to keep indices correct when updating.
 */
export function reversedLines() {
  const lines: Line[] = [];
  const ranges = selectedRanges();

  for (const { from, to } of ranges) {
    lines.push(...linesWithRange(from, to));
  }

  return lines.reverse();
}

export function linesWithRange(from: number, to: number) {
  const editor = window.editor;
  const doc = editor.state.doc;

  const lines: Line[] = [];
  const start = doc.lineAt(from).number;
  const end = doc.lineAt(to).number;

  for (let ln = start; ln <= end; ++ln) {
    lines.push(doc.line(ln));
  }

  return lines;
}

/**
 * Returns the text of selection when we only care about one selection.
 *
 * @returns Text of the main selection
 */
export function selectedMainText(): string {
  const state = window.editor.state;
  const { from, to } = state.selection.main;
  return state.sliceDoc(from, to);
}

/**
 * Select line based on mouse event, e.g., clicking on gutter number to select the whole line.
 *
 * @param event
 */
export function selectWholeLineIfNeeded(event: MouseEvent) {
  const target = event.target;
  if (target instanceof HTMLDivElement && target.classList.contains('cm-gutterElement')) {
    selectWholeLineAt(parseInt(target.innerText));
  }
}

export function selectAll() {
  const editor = window.editor;
  editor.dispatch({
    selection: EditorSelection.range(0, editor.state.doc.length),
  });
}

export function scrollToSelection(strategy: 'nearest' | 'start' | 'end' | 'center' = 'center', margin = 5) {
  const editor = window.editor;
  const range = editor.state.selection.main;
  editor.dispatch({
    effects: EditorView.scrollIntoView(range, { y: strategy, yMargin: margin }),
  });
}

export function getRect(pos: number) {
  const rect = window.editor.coordsAtPos(pos);
  if (rect === null) {
    return undefined;
  }

  return getClientRect(rect);
}

export function gotoLine(lineNumber: number) {
  const editor = window.editor;
  const state = editor.state;
  const pos = state.doc.line(lineNumber).from;

  editor.dispatch({ selection: EditorSelection.cursor(pos) });
  scrollToSelection();
}

/**
 * Make sure caret is visible, with an additional margin to breath.
 */
export function scrollCaretToVisible() {
  const editor = window.editor;
  const pos = editor.state.selection.main.to;
  scrollPositionToVisible(pos);
}

/**
 * Make sure selected search match is visible, with an additional margin to breath.
 */
export function scrollSearchMatchToVisible(foundRange?: SelectionRange) {
  const pos = searchMatchPosition() ?? foundRange?.from;
  if (pos !== undefined) {
    scrollPositionToVisible(pos);
  }
}

/**
 * Make sure text position is visible, with an additional margin to breath.
 */
export function scrollPositionToVisible(pos: number) {
  const editor = window.editor;
  editor.dispatch({
    effects: EditorView.scrollIntoView(pos, { y: 'end', yMargin: 72 }),
  });
}

export function updateActiveLine(hasSelection: boolean) {
  // Update invisible behavior as selection changed
  const invisiblesBehavior = window.config.invisiblesBehavior;
  if (invisiblesBehavior === InvisiblesBehavior.selection) {
    setInvisiblesBehavior(invisiblesBehavior);
  }

  // Clear active line background when there's selection,
  // it makes the selection easier to read.
  setShowActiveLineIndicator(!hasSelection && window.config.showActiveLineIndicator);

  // Toggling extensions does not trigger an immediate repaint,
  // refresh the focus manually.
  refreshEditFocus();
}

/**
 * Refresh the current focus to force a render pass.
 */
export function refreshEditFocus() {
  const editor = window.editor;
  editor.dispatch({
    selection: editor.state.selection,
    userEvent: 'select', // Fake a user event
  });
}

export { selectedLineColumn } from './selectedLineColumn';
