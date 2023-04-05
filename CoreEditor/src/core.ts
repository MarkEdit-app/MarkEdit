import { EditorView } from '@codemirror/view';
import { StateEffect } from '@codemirror/state';
import { editingState } from './common/store';
import replaceSelections from './modules/commands/replaceSelections';

import * as extensions from './extensions';
import * as styling from './styling/config';
import * as themes from './styling/themes';
import * as lineEndings from './modules/lineEndings';
import * as completion from './modules/completion';
import * as grammarly from './modules/grammarly';
import * as selection from './modules/selection';

export enum ReplaceGranularity {
  wholeDocument = 'wholeDocument',
  selection = 'selection',
}

/**
 * Reset the editor to the initial state.
 *
 * @param doc Initial content
 */
export function resetEditor(doc: string) {
  // eslint-disable-next-line
  if (window.editor && window.editor.destroy) {
    window.editor.destroy();
  }

  const options = {
    lineBreak: lineEndings.getLineBreak(doc, window.config.defaultLineBreak),
  };

  // Bootstrap the editor with only minimal extensions
  const editor = new EditorView({
    doc,
    parent: document.querySelector('#editor') ?? document.body,
    extensions: extensions.minimal(options),
  });

  // To let users see the content asap, we reconfigure with all extensions later,
  // we use 350 here because it usually takes 300ms to finish launch.
  setTimeout(() => {
    editor.dispatch({
      effects: StateEffect.reconfigure.of(extensions.all(options)),
    });
  }, 350);

  editor.focus();
  window.editor = editor;
  selection.scrollCaretToVisible(); // coordsAtPos ensures the line number height

  const scrollDOM = editor.scrollDOM;
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
  styling.setUp(window.config, themes.loadTheme(window.config.theme).accentColor);

  // After calling editor.focus(), the selection is set to [Ln 1, Col 1]
  window.nativeModules.core.notifySelectionDidChange({
    lineColumn: { line: 1 as CodeGen_Int, column: 1 as CodeGen_Int, length: 0 as CodeGen_Int },
    contentEdited: false,
  });
}

/**
 * Clear the editor, set the content to empty.
 */
export function clearEditor() {
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

export function markEditorDirty(isDirty: boolean) {
  editingState.isDirty = isDirty;
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

const storage: { scrollTimer: ReturnType<typeof setTimeout> | undefined } = {
  scrollTimer: undefined,
};
