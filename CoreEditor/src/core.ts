import { EditorView } from '@codemirror/view';
import { extensions } from './extensions';
import { editingState } from './common/store';
import { getViewportScale } from './common/utils';
import replaceSelections from './modules/commands/replaceSelections';

import * as styling from './styling/config';
import * as themes from './styling/themes';
import * as lineEndings from './modules/lineEndings';
import * as completion from './modules/completion';
import * as grammarly from './modules/grammarly';
import * as selection from './modules/selection';
import * as history from './modules/history';

export enum ReplaceGranularity {
  wholeDocument = 'wholeDocument',
  selection = 'selection',
}

/**
 * Reset the editor to the initial state.
 *
 * @param doc Initial content
 * @param readOnly Whether to make the editor read-only
 */
export function resetEditor(doc: string, readOnly = false) {
  // Idle state change should always go first
  editingState.isIdle = false;

  // eslint-disable-next-line
  if (window.editor && window.editor.destroy) {
    window.editor.destroy();
  }

  const lineBreak = lineEndings.getLineBreak(
    doc,
    window.config.defaultLineBreak
  );

  const editor = new EditorView({
    doc: lineEndings.normalizeLineBreaks(doc, lineBreak),
    parent: document.querySelector('#editor') ?? document.body,
    extensions: extensions({ readOnly, lineBreak }),
  });

  editor.focus();
  window.editor = editor;

  // coordsAtPos ensures the line number height
  selection.scrollCaretToVisible();
  // Makes sure the content doesn't have unwanted inset
  editor.dispatch({ effects: EditorView.scrollIntoView(0) });

  const scrollDOM = editor.scrollDOM;
  scrollDOM.scrollTo({ top: 0 }); // scrollIntoView doesn't work when the app is idle
  fixWebKitWheelIssues(scrollDOM);

  scrollDOM.addEventListener('scroll', () => {
    // Dismiss the completion panel whenever the dom scrolls
    if (completion.isPanelVisible()) {
      window.nativeModules.completion.cancelCompletion();
    }

    // Trick to stop Grammarly from working until scroll stops
    storage.scrollTimer = (() => {
      if (storage.scrollTimer !== undefined) {
        clearTimeout(storage.scrollTimer);
      }

      grammarly.setIdle(true);
      return setTimeout(() => grammarly.setIdle(false), 100);
    })();
  });

  // Recofigure, window.config might have changed
  styling.setUp(window.config, themes.loadTheme(window.config.theme).colors);

  // After calling editor.focus(), the selection is set to [Ln 1, Col 1]
  window.nativeModules.core.notifyViewDidUpdate({
    contentEdited: false,
    isDirty: false,
    selectedLineColumn: {
      line: 1 as CodeGen_Int,
      column: 1 as CodeGen_Int,
      length: 0 as CodeGen_Int,
    },
  });

  // Observe viewport scale changes, i.e., pinch to zoom
  window.visualViewport?.addEventListener('resize', () => {
    const viewportScale = getViewportScale();
    if (Math.abs(viewportScale - storage.viewportScale) > 0.001) {
      window.nativeModules.core.notifyViewportScaleDidChange();
      storage.viewportScale = viewportScale;
    }
  });

  // The content should be initially clean
  history.markContentClean();
}

/**
 * Clear the editor, set the content to empty.
 */
export function clearEditor() {
  // Idle state change should always go first
  editingState.isIdle = true;

  const editor = window.editor;
  editor.dispatch({
    changes: { from: 0, to: editor.state.doc.length, insert: '' },
  });
}

export function getEditorText() {
  const state = window.editor.state;
  if (state.lineBreak === '\n') {
    return state.doc.toString();
  }

  // It looks like state.doc.toString() always uses LF instead of state.lineBreak
  const lines: string[] = [];
  for (let index = 1; index <= state.doc.lines; ++index) {
    lines.push(state.doc.line(index).text);
  }

  // Re-join with specified line break, might be CRLF for example
  return lines.join(state.lineBreak);
}

export function insertText(text: string, from: number, to: number) {
  const editor = window.editor;
  editor.dispatch({
    changes: { from, to, insert: text },
  });
}

export function replaceText(text: string, granularity: ReplaceGranularity) {
  switch (granularity) {
    case ReplaceGranularity.wholeDocument:
      insertText(text, 0, window.editor.state.doc.length);
      break;
    case ReplaceGranularity.selection:
      replaceSelections(text);
      break;
  }
}

export function handleMouseEntered(clientX: number, _clientY: number) {
  const gutterDOM = document.querySelector('.cm-gutters') as HTMLElement | null;
  if (gutterDOM === null) {
    return;
  }

  const gutterRect = gutterDOM.getBoundingClientRect();
  const rightToLeft = gutterRect.left > 20;

  // Check if the point is inside the gutters, RTL is guessed with a margin.
  //
  // To keep it simple, this doesn't take magnification into account.
  if (clientX > 0 && clientX < gutterRect.width || rightToLeft && clientX > gutterRect.left && clientX < gutterRect.right) {
    styling.setGutterHovered(true);
  }
}

export function handleMouseExited(_clientX: number, _clientY: number) {
  styling.setGutterHovered(false);
}

function fixWebKitWheelIssues(scrollDOM: HTMLElement) {
  // Fix the vertical scrollbar initially visible for short documents
  scrollDOM.style.overflow = 'hidden';
  setTimeout(() => scrollDOM.style.overflow = 'auto', 300);

  // Dirty fix to a WebKit bug,
  // the vertical scrollbar won't be hidden after the element is scrolled horizontally.
  //
  // This fix doesn't make any sense, it cannot be explained,
  // however, it just works™.
  scrollDOM.addEventListener('wheel', () => { /* no-op */ });
}

const storage: {
  scrollTimer: ReturnType<typeof setTimeout> | undefined;
  viewportScale: number;
} = {
  scrollTimer: undefined,
  viewportScale: 1.0,
};
