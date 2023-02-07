import { EditorView } from '@codemirror/view';
import { Extension, EditorSelection } from '@codemirror/state';
import { markdown, markdownLanguage } from '../@vendor/lang-markdown';

export function setUp(doc: string, extensions: Extension = []) {
  const editor = new EditorView({
    doc,
    parent: document.body,
    extensions: [
      ...[extensions],
      markdown({ base: markdownLanguage }),
    ],
  });

  editor.focus();
  window.editor = editor;
}

export function setText(doc: string) {
  window.editor.dispatch({
    changes: {
      insert: doc,
      from: 0, to: window.editor.state.doc.length,
    },
    selection: EditorSelection.cursor(0),
  });
}

export function getText() {
  return window.editor.state.doc.toString();
}

export function selectAll() {
  selectRange(0);
}

export function selectRange(from: number, to?: number) {
  window.editor.dispatch({
    selection: EditorSelection.range(from, to === undefined ? window.editor.state.doc.length - from : to),
  });
}
