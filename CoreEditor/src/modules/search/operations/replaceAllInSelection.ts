import { SearchQuery } from '@codemirror/search';
import { cursorFromQuery } from '../cursorFromQuery';
import SearchOptions from '../options';
import selectedRanges from '../../selection/selectedRanges';

export default function replaceAllInSelection(options: SearchOptions) {
  const cursor = cursorFromQuery(new SearchQuery(options));
  if (cursor === null) {
    return;
  }

  const editor = window.editor;
  const state = editor.state;
  const changes = (cursor.matchAll(state, 1e9) ?? []).map(match => ({
    from: match.from,
    to: match.to,
    insert: cursor.getReplacement(match),
  }));

  const selections = selectedRanges();
  editor.dispatch({
    changes: changes.filter(({ from, to }) => {
      for (const selection of selections) {
        if (from >= selection.from && to <= selection.to) {
          return true;
        }
      }

      return false;
    }),
  });
}
