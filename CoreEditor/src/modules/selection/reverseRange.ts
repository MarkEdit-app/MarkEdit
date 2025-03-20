import { EditorSelection, SelectionRange } from '@codemirror/state';

export default function invertRange(range: SelectionRange, needsInvert: boolean) {
  if (needsInvert) {
    return EditorSelection.range(range.to, range.from);
  }

  return range;
}
