import { EditorSelection, SelectionRange } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import selectedRanges from '../selection/selectedRanges';

/**
 * Toggle selection with mark pairs, such as **bold**, _italic_.
 *
 * @param leftMark Mark on the left side
 * @param rightMark Mark on the right side
 * @param mainNodeName The name of the main node around caret
 * @param markNodeName The name of the mark node around caret
 */
export default function toggleBlockWithMarks(leftMark: string, rightMark: string, mainNodeName?: string, markNodeName?: string) {
  const editor = window.editor;
  const state = editor.state;
  const hasNodeNames = mainNodeName !== undefined && markNodeName !== undefined;

  if (hasNodeNames) {
    // Ideally this should be a Set, but we are not going have tons of carets
    const nodeRanges: SelectionRange[] = [];
    const rangesToKeep: SelectionRange[] = [];

    // Go through all ranges, remove duplicate ones if we have multiple carets inside one node
    for (const range of selectedRanges()) {
      const tree = syntaxTree(state);
      const node = tree.resolve(range.from);

      if (node.name === mainNodeName && node.getChildren(markNodeName).length === 2) {
        if (nodeRanges.some(({ from, to }) => (node.from >= from && node.from <= to) || (node.to >= from && node.to <= to))) {
          continue;
        }

        nodeRanges.push(EditorSelection.range(node.from, node.to));
      }

      rangesToKeep.push(range);
    }

    editor.dispatch({
      selection: EditorSelection.create(rangesToKeep),
    });
  }

  // Take care of all updates and merge them into a single one
  const updates = editor.state.changeByRange(({ from, to }) => {
    if (hasNodeNames) {
      const tree = syntaxTree(state);
      const node = tree.resolve(from);

      // Remove marks if the caret is inside a formatted node
      if (node.name === mainNodeName) {
        const markNodes = node.getChildren(markNodeName);
        if (markNodes.length === 2) {
          const markBegin = markNodes[0];
          const markEnd = markNodes[1];
          const removedLength = markBegin.to - markBegin.from;
          return {
            range: EditorSelection.range(from - removedLength, to - removedLength),
            changes: {
              from: node.from,
              to: node.to,
              insert: state.sliceDoc(markBegin.to, markEnd.from),
            },
          };
        } else {
          console.error(`Invalid length of marks: ${markNodes.length}`);
        }
      }
    }

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
