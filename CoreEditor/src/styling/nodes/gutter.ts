import { Decoration, DecorationSet, lineNumbers } from '@codemirror/view';
import { codeFolding, foldGutter, foldState } from '@codemirror/language';

export const gutterExtensions = [
  lineNumbers(),
  codeFolding({ placeholderText: '•••' }),
  foldGutter({ openText: '▼', closedText: '▶︎' }),
];

export function isPositionFolded(pos: number) {
  let rangeSet: DecorationSet = Decoration.none;
  let isFolded = false;

  try {
    rangeSet = window.editor.state.field(foldState);
  } catch {
    return false;
  }

  rangeSet.between(pos, pos, (from, to) => {
    if (pos >= from && pos < to) {
      isFolded = true;
      return false;
    }
  });

  return isFolded;
}
