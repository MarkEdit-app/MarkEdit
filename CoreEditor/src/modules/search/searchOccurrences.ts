import { SelectionRange, EditorSelection } from '@codemirror/state';

export default function searchOccurrences(text: string, query: string) {
  const ranges: SelectionRange[] = [];
  let index = -1;

  // Case senstive, naive search
  while ((index = text.indexOf(query, index + 1)) >= 0) {
    const from = index;
    const to = index + query.length;
    ranges.push(EditorSelection.range(from, to));
  }

  return ranges;
}
