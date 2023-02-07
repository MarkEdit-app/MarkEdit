import { EditorSelection } from '@codemirror/state';

/**
 * Select the whole line, it's slightly different compared to the CodeMirror built-in one,
 * more specifically, it doesn't include the following linebreak.
 *
 * @param n 1-based line number
 */
export default function selectWholeLineAt(n: number) {
  try {
    const editor = window.editor;
    const line = editor.state.doc.line(n);
    editor.dispatch({ selection: EditorSelection.range(line.from, line.to) });
  } catch (error) {
    // The state.doc.line can *sometimes* throw exceptions, haven't looked into it,
    // but we don't want to make other features non-functional.
    console.error(error);
  }
}
