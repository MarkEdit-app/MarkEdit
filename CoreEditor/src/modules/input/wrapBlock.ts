import { EditorSelection } from '@codemirror/state';
import { EditorView } from '@codemirror/view';

/**
 * Wrap selected blocks with a pair of mark.
 *
 * @param mark The mark, e.g., "*"
 */
export default function wrapBlock(mark: string, editor: EditorView) {
  // Fallback to the default behavior if all selections are empty
  if (!editor.state.selection.ranges.some(range => !range.empty)) {
    return false;
  }

  const state = editor.state;
  editor.dispatch(editor.state.changeByRange(({ from, to }) => {
    const selection = state.sliceDoc(from, to);
    const replacement = from === to ? mark : `${mark}${selection}${mark}`;
    const newPos = from + mark.length;
    return {
      range: EditorSelection.range(newPos, newPos + selection.length),
      changes: {
        from, to, insert: replacement,
      },
    };
  }));

  // Intercepted, default behavior is ignored
  return true;
}
