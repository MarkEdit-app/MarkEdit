import { EditorView } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { extensions } from './extensions';
import { globalState, editingState } from './common/store';
import { almostEqual, afterDomUpdate, getViewportScale, isReleaseMode } from './common/utils';

import hasSelection from './modules/selection/hasSelection';
import replaceSelections from './modules/commands/replaceSelections';

import { resetKeyStates } from './modules/events';
import { setUp, setGutterHovered } from './styling/config';
import { notifyBackgroundColor } from './styling/helper';
import { loadTheme } from './styling/themes';
import { recalculateTextMetrics } from './modules/config';
import { getReadableContent } from './modules/lezer';
import { getLineBreak, normalizeLineBreaks } from './modules/lineEndings';
import { removeFrontMatter } from './modules/frontMatter';
import { selectedMainText, scrollIntoView } from './modules/selection';
import { markContentClean } from './modules/history';

import { TextEditor } from './api/editor';
import { editorReadyListeners } from './api/methods';

// Work around a WebKit bug, text jiggles back and forth when resizing the window
window.addEventListener('resize', () => {
  const editor = window.editor as EditorView | null;
  if (typeof editor?.requestMeasure === 'function') {
    editor.requestMeasure();
  }
});

// Observe viewport scale changes, i.e., pinch to zoom
window.visualViewport?.addEventListener('resize', () => {
  const viewportScale = getViewportScale();
  if (!almostEqual(viewportScale, storage.viewportScale)) {
    window.nativeModules.core.notifyViewportScaleDidChange();
    storage.viewportScale = viewportScale;
  }
});

type ReadableContent = {
  sourceText: string;
  trimmedText: string;
  paragraphCount: CodeGen_Int;
  commentCount: CodeGen_Int;
};

export interface ReadableContentPair {
  fullText: ReadableContent;
  selection?: ReadableContent;
}

export enum ReplaceGranularity {
  wholeDocument = 'wholeDocument',
  selection = 'selection',
}

/**
 * Reset the editor to the initial state.
 */
export function resetEditor(initialContent: string) {
  // Idle state change should always go first
  editingState.isIdle = false;

  // eslint-disable-next-line
  if (window.editor && window.editor.destroy) {
    window.editor.destroy();
  }

  const lineBreak = getLineBreak(
    initialContent,
    window.config.defaultLineBreak,
  );

  const editor = new EditorView({
    doc: normalizeLineBreaks(initialContent, lineBreak),
    parent: document.querySelector('#editor') ?? document.body,
    extensions: extensions({ lineBreak }),
  });

  editor.focus();
  window.editor = editor;

  MarkEdit.editorView = editor;
  (MarkEdit.editorAPI as TextEditor).setView(editor);

  const ensureLineHeight = () => {
    // coordsAtPos ensures the line number height
    const caretPos = editor.state.selection.main.to;
    const coords = editor.coordsAtPos(caretPos);
    if (!isReleaseMode) {
      console.log('Ensuring line height', coords);
    }
  };

  // Ensure twice, the first one is for initial launch,
  // the latter is for a special case where the window moves to the background during launch.
  ensureLineHeight();
  setTimeout(ensureLineHeight, 600);

  // Makes sure the content doesn't have unwanted inset
  scrollIntoView(0, window.config.typewriterMode ? 'center' : undefined);

  const contentDOM = editor.contentDOM;
  contentDOM.addEventListener('blur', handleFocusLost);

  const scrollDOM = editor.scrollDOM;
  scrollDOM.scrollTo({ top: 0 }); // scrollIntoView doesn't work when the app is idle

  observeContentHeightChanges(scrollDOM);
  fixWebKitWheelIssues(scrollDOM);

  if ('onscrollend' in window) { // [macOS] 26.2
    scrollDOM.addEventListener('scrollend', () => {
      window.nativeModules.core.notifyContentOffsetDidChange();
    });
  } else {
    scrollDOM.addEventListener('scroll', () => {
      if (storage.scrollTimer !== undefined) {
        clearTimeout(storage.scrollTimer);
        storage.scrollTimer = undefined;
      }

      storage.scrollTimer = setTimeout(() => {
        window.nativeModules.core.notifyContentOffsetDidChange();
      }, 100);
    });
  }

  // Recofigure, window.config might have changed
  setUp(window.config, loadTheme(window.config.theme).colors);
  observeBackgroundColorChanges(editor.dom);
  afterDomUpdate(notifyBackgroundColor);

  // eslint-disable-next-line compat/compat
  requestAnimationFrame(() => recalculateTextMetrics());

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

  // The content should be initially clean
  markContentClean();

  // For user scripts, notify the editor is ready
  editorReadyListeners().forEach(listener => listener(editor));
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

export function getEditorState() {
  return {
    hasFocus: window.editor.hasFocus,
    hasSelection: hasSelection(),
  };
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

export function getReadableContentPair(): ReadableContentPair {
  const getContent = (sourceText: string): ReadableContent => {
    // Remove front matter and parse the content to get paragraphs and comments
    const actualText = removeFrontMatter(sourceText);
    const { trimmedText, paragraphCount, commentCount } = getReadableContent(actualText);

    return {
      sourceText,
      trimmedText,
      paragraphCount: paragraphCount as CodeGen_Int,
      commentCount: commentCount as CodeGen_Int,
    };
  };

  return {
    fullText: getContent(getEditorText()),
    selection: (() => {
      // Get readable content for selection if the selection is not empty.
      const selectedText = selectedMainText();
      return selectedText.length > 0 ? getContent(selectedText) : undefined;
    })(),
  };
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

export function setHasModalSheet(value: boolean) {
  globalState.hasModalSheet = value;
}

function observeContentHeightChanges(scrollDOM: HTMLElement) {
  const notifyIfChanged = () => {
    const panel = window.editor.dom.querySelector('.cm-panels-bottom');
    const height = panel === null ? 0 : panel.getBoundingClientRect().height;
    if (almostEqual(storage.bottomPanelHeight, height)) {
      return;
    }

    storage.bottomPanelHeight = height;
    window.nativeModules.core.notifyContentHeightDidChange({
      bottomPanelHeight: height,
    });
  };

  // eslint-disable-next-line compat/compat
  const observer = new ResizeObserver(notifyIfChanged);
  observer.observe(scrollDOM);
  notifyIfChanged();
}

function observeBackgroundColorChanges(element: HTMLElement) {
  const observer = new MutationObserver(() => {
    const currentColor = getComputedStyle(element).backgroundColor;
    if (currentColor !== storage.backgroundColor) {
      storage.backgroundColor = currentColor;
      notifyBackgroundColor(currentColor);
    }
  });

  observer.observe(element, {
    attributes: true,
    attributeFilter: ['class', 'style'],
    subtree: false,
  });
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
  backgroundColor: string;
  viewportScale: number;
  bottomPanelHeight: number;
} = {
  scrollTimer: undefined,
  backgroundColor: '',
  viewportScale: 1.0,
  bottomPanelHeight: 0.0,
};
