import { EditorView } from '@codemirror/view';
import { EditorSelection, Line, SelectionRange } from '@codemirror/state';
import { selectAll as selectAllCommand } from '@codemirror/commands';
import { isReleaseMode } from '../../common/utils';
import { almostEqual, afterDomUpdate, getClientRect } from '../../common/utils';

import { InvisiblesBehavior } from '../../config';
import { linesWithRange } from '../lines';
import { setInvisiblesBehavior } from '../config';
import { setShowActiveLineIndicator } from '../../styling/config';
import { saveGoBackSelection } from './navigate';

import selectedRanges from './selectedRanges';
import selectWholeLineAt from './selectWholeLineAt';
import searchMatchElement from './searchMatchElement';

type ScrollStrategy = 'nearest' | 'start' | 'end' | 'center';

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

export function selectWholeDocument() {
  if (window.editor.hasFocus) {
    selectAllCommand(window.editor);
  }
}

/**
 * Select line based on mouse event, e.g., clicking on gutter number to select the whole line.
 *
 * @param event
 */
export function selectWholeLineIfNeeded(event: MouseEvent) {
  const target = (() => {
    const element = event.target;
    if (element instanceof HTMLElement && element.classList.contains('cm-foldGutter')) {
      return element.parentElement;
    }

    return element;
  })();

  if (!(target instanceof HTMLDivElement) || !target.classList.contains('cm-gutters')) {
    return;
  }

  const gutterElements = [...target.querySelectorAll('.cm-gutterElement')];
  if (!isReleaseMode) {
    console.log(`Found ${gutterElements.length} gutter elements`);
  }

  // For a better experience of selecting multiple lines, ".cm-gutterElement" ignores user interactions,
  // we need to find the actual clicked gutter element manually.
  const actualElement = gutterElements.find(element => {
    const rect = element.getBoundingClientRect();
    if (rect.top < event.clientY && rect.bottom > event.clientY) {
      return element;
    }

    return undefined;
  }) as HTMLElement | undefined;

  if (actualElement !== undefined) {
    selectWholeLineAt(parseInt(actualElement.innerText));
  }
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

  saveGoBackSelection();
  editor.dispatch({ selection: EditorSelection.cursor(pos) });
  scrollToSelection();
}

/**
 * Make sure caret is visible, with an additional margin to breath.
 */
export function scrollCaretToVisible(strategy: ScrollStrategy = 'end') {
  const editor = window.editor;
  const pos = editor.state.selection.main.to;
  const coords = editor.coordsAtPos(pos);
  const margin = 55;

  if (coords === null) {
    return scrollIntoView(pos);
  }

  if (coords.bottom + margin > editor.dom.clientHeight) {
    return scrollToSelection(strategy, margin);
  }
}

/**
 * Make sure selected search match is visible, with an additional margin to breath.
 */
export function scrollSearchMatchToVisible(strategy: ScrollStrategy = 'center') {
  const element = searchMatchElement();
  if (element === null) {
    return;
  }

  const pos = window.editor.posAtDOM(element);
  scrollIntoView(pos, strategy);
}

/**
 * Make sure text selection is visible, with an additional margin to breath.
 */
export function scrollToSelection(strategy: ScrollStrategy = 'center', margin = 5) {
  const range = window.editor.state.selection.main;
  scrollIntoView(range, strategy, margin);
}

export function scrollIntoView(anchor: number | SelectionRange, strategy: ScrollStrategy = 'nearest', margin = 5) {
  const editor = window.editor;
  const currentOffset = editor.scrollDOM.scrollTop;

  const tryToScroll = (strategy: ScrollStrategy) => {
    editor.dispatch({
      effects: EditorView.scrollIntoView(anchor, { y: strategy, yMargin: margin }),
    });
  };

  // Try with the suggested strategy
  tryToScroll(strategy);

  // Try centering if the suggested strategy failed
  afterDomUpdate(() => {
    if (almostEqual(editor.scrollDOM.scrollTop, currentOffset)) {
      tryToScroll('center');
    }
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

export function isElementVisible(element: Element) {
  return isRectVisible(element.getBoundingClientRect());
}

export function isPositionVisible(pos: number) {
  return isRectVisible(window.editor.coordsAtPos(pos));
}

export { selectedLineColumn } from './selectedLineColumn';

function isRectVisible(rect: { top: number; bottom: number } | null) {
  return rect !== null && rect.top >= 0 && rect.bottom <= window.editor.dom.clientHeight;
}
