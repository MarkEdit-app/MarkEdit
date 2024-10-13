import { EditorSelection } from '@codemirror/state';
import { EditorView } from '@codemirror/view';

/**
 * When backtick key is detected, try inserting a code block if we already have two backticks.
 */
export default function insertCodeBlock(editor: EditorView) {
  const state = editor.state;
  const doc = state.doc;
  const mark = '`';
  const prefix = mark + state.lineBreak;

  editor.dispatch(state.changeByRange(({ from, to }) => {
    if (doc.sliceString(from - 2, from) !== `${mark}${mark}`) {
      // Fallback to inserting only one backtick
      return {
        range: EditorSelection.cursor(from + mark.length),
        changes: { from, to, insert: mark },
      };
    }

    // Insert an empty code block and move the cursor to the empty line
    return {
      range: EditorSelection.cursor(from + prefix.length),
      changes: {
        from, to, insert: prefix + `${state.lineBreak}${mark}${mark}${mark}`,
      },
    };
  }));

  // Intercepted, default behavior is ignored
  return true;
}
