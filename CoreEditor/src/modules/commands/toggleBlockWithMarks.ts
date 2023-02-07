import { EditorSelection } from '@codemirror/state';

/**
 * Toggle selection with mark pairs, such as **bold**, _italic_.
 *
 * @param leftMark Mark on the left side
 * @param rightMark Mark on the right side
 */
export default function toggleBlockWithMarks(leftMark: string, rightMark: string) {
  const editor = window.editor;
  const doc = editor.state.doc;

  // Take care of all updates and merge them into a single one
  const updates = editor.state.changeByRange(({ from, to }) => {
    const startPos = from;
    const endPos = to;
    const selectedText = doc.sliceString(from, to);

    const startTestPos = startPos - leftMark.length;
    const endTestPos = endPos + rightMark.length;

    let matched = false;
    let newPos = 0;

    if (startTestPos >= 0 && endTestPos <= doc.length) {
      const leftTest = doc.sliceString(startTestPos, startTestPos + leftMark.length);
      const rightTest = doc.sliceString(endTestPos - rightMark.length, endTestPos);
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
