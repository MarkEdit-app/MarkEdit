import { EditorSelection } from '@codemirror/state';

/**
 * Toggle selection with mark pairs, such as **bold**, _italic_.
 *
 * @param leftMark Mark on the left side
 * @param rightMark Mark on the right side
 */
export default function toggleBlockWithMarks(leftMark: string, rightMark: string) {
  const editor = window.editor;
  const state = editor.state;

  // Take care of all updates and merge them into a single one
  const updates = editor.state.changeByRange(({ from, to }) => {
    const startPos = from;
    const endPos = to;
    const selectedText = state.sliceDoc(from, to);

    const startTestPos = startPos - leftMark.length;
    const endTestPos = endPos + rightMark.length;

    let matched = false;
    let newPos = 0;

    if (startTestPos >= 0 && endTestPos <= state.doc.length) {
      const leftTest = state.sliceDoc(startTestPos, startTestPos + leftMark.length);
      const rightTest = state.sliceDoc(endTestPos - rightMark.length, endTestPos);
      matched = leftTest === leftMark && rightTest === rightMark;
    }

    if (matched) {
      newPos = startTestPos;
      return {
        range: EditorSelection.range(newPos, newPos + selectedText.length),
        changes: {
          from: startTestPos, to: endTestPos, insert: selectedText,
        },
      };
    } else {
      newPos = startPos + leftMark.length;
      return {
        range: EditorSelection.range(newPos, newPos + selectedText.length),
        changes: {
          from: startPos, to: endPos, insert: `${leftMark}${selectedText}${rightMark}`,
        },
      };
    }
  });

  editor.dispatch(updates);
}
