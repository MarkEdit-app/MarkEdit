import { EditorView } from '@codemirror/view';
import { extensions } from './extensions';
import { editingState } from './common/store';
import replaceSelections from './modules/commands/replaceSelections';

import * as styling from './styling/config';
import * as themes from './styling/themes';
import * as history from './modules/history';
import * as lineEndings from './modules/lineEndings';
import * as completion from './modules/completion';

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

  const editor = new EditorView({
    doc,
    parent: document.querySelector('#editor') ?? document.body,
    extensions: extensions({
      lineBreak: lineEndings.getLineBreak(doc, window.config.defaultLineBreak),
    }),
  });

  // Dirty trick, the line number height is not initially correct because of window animations,
  // this approach forces a layout pass.
  if (window.config.showLineNumbers) {
    editingState.isDirty = true;
    setTimeout(() => editingState.isDirty = false, 50);
    editor.dispatch({ changes: { from: 0, insert: '\u200b' } });
    editor.dispatch({ changes: { from: 0, to: 1, insert: '' } });
    history.clearHistory();
  }

  editor.focus();
  window.editor = editor;

  const scrollDOM = editor.scrollDOM;
  fixWebKitWheelIssues(scrollDOM);

  // Dismiss the completion panel whenever the dom scrolls
  scrollDOM.addEventListener('scroll', () => {
    if (completion.isPanelVisible()) {
      window.nativeModules.completion.cancelCompletion();
    }
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
  // however, it just works???.
  scrollDOM.addEventListener('wheel', () => { /* no-op */ });
}
