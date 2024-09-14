import { EditorView } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { extensions } from './extensions';
import { editingState } from './common/store';
import { getViewportScale, notifyBackgroundColor } from './common/utils';
import replaceSelections from './modules/commands/replaceSelections';

import { resetKeyStates } from './events';
import { setUp, setGutterHovered } from './styling/config';
import { loadTheme } from './styling/themes';
import { getLineBreak, normalizeLineBreaks } from './modules/lineEndings';
import { generateDiffs } from './modules/diff';
import { scrollCaretToVisible, scrollIntoView } from './modules/selection';
import { markContentClean } from './modules/history';

export enum ReplaceGranularity {
  wholeDocument = 'wholeDocument',
  selection = 'selection',
}

/**
 * Reset the editor to the initial state.
 *
 * @param doc Initial content
 * @param revision Optionally, provide a revision to show diff
 * @param revisionMode Whether to set the editor to revision mode
 */
export function resetEditor(
  doc: string,
  revision: string | undefined = undefined,
  revisionMode = false,
) {
  // Idle state change should always go first
  editingState.isIdle = false;

  // eslint-disable-next-line
  if (window.editor && window.editor.destroy) {
    window.editor.destroy();
  }

  const lineBreak = getLineBreak(
    doc,
    window.config.defaultLineBreak,
  );

  // Returns either the original doc,
  // or content that contains the diff with labels.
  const initialContent = (() => {
    if (revision === undefined) {
      return doc;
    }

    return generateDiffs(revision, doc);
  })();

  const editor = new EditorView({
    doc: normalizeLineBreaks(initialContent, lineBreak),
    parent: document.querySelector('#editor') ?? document.body,
    extensions: extensions({ revisionMode, lineBreak }),
  });

  editor.focus();
  window.editor = editor;

  const ensureLineHeight = () => {
    // coordsAtPos ensures the line number height
    scrollCaretToVisible();
  };

  // Ensure twice, the first one is for initial launch,
  // the latter is for a special case where the window moves to the background during launch.
  ensureLineHeight();
  setTimeout(ensureLineHeight, 600);

  // Makes sure the content doesn't have unwanted inset
  scrollIntoView(0);

  const contentDOM = editor.contentDOM;
  contentDOM.addEventListener('blur', handleFocusLost);

  const scrollDOM = editor.scrollDOM;
  scrollDOM.scrollTo({ top: 0 }); // scrollIntoView doesn't work when the app is idle
  fixWebKitWheelIssues(scrollDOM);

  scrollDOM.addEventListener('scroll', () => {
    if (storage.scrollTimer !== undefined) {
      clearTimeout(storage.scrollTimer);
      storage.scrollTimer = undefined;
    }

    storage.scrollTimer = setTimeout(() => {
      window.nativeModules.core.notifyContentOffsetDidChange();
    }, 100);
  });

  // Recofigure, window.config might have changed
  setUp(window.config, loadTheme(window.config.theme).colors);
  setTimeout(notifyBackgroundColor, 100);

  // After calling editor.focus(), the selection is set to [Ln 1, Col 1]
  window.nativeModules.core.notifyViewDidUpdate({
    contentEdited: false,
    compositionEnded: true,
    isDirty: false,
    selectedLineColumn: {
      lineNumber: 1 as CodeGen_Int,
      columnText: '',
      selectionText: '',
    },
  });

  // Work around a WebKit bug, text jiggles back and forth when resizing the window
  window.addEventListener('resize', () => editor.requestMeasure());

  // Observe viewport scale changes, i.e., pinch to zoom
  window.visualViewport?.addEventListener('resize', () => {
    const viewportScale = getViewportScale();
    if (Math.abs(viewportScale - storage.viewportScale) > 0.001) {
      window.nativeModules.core.notifyViewportScaleDidChange();
      storage.viewportScale = viewportScale;
    }
  });

  // The content should be initially clean
  markContentClean();
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
    selection: EditorSelection.cursor(from + text.length),
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

export function handleFocusLost() {
  resetKeyStates();
}

export function handleMouseExited(_clientX: number, _clientY: number) {
  setGutterHovered(false);
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

  // Dirty fix to a CodeMirror bug,
  // dragging the scrollbar is super laggy because of unnecessary updates.
  //
  // Better to fix CodeMirror at some point.
  scrollDOM.addEventListener('mousedown', event => {
    const target = event.target as HTMLElement;
    const clientX = event.clientX;
    const clientWidth = target.clientWidth;
    const scrollbarWidth = 15; // Just a random guess, not necessary to be precise

    const shouldPreventDefault = (() => {
      if (target.dir === 'rtl') {
        return clientX < scrollbarWidth;
      } else {
        return clientX > clientWidth - scrollbarWidth;
      }
    })();

    if (shouldPreventDefault) {
      event.preventDefault();
    }
  });
}

const storage: {
  scrollTimer: ReturnType<typeof setTimeout> | undefined;
  viewportScale: number;
} = {
  scrollTimer: undefined,
  viewportScale: 1.0,
};
