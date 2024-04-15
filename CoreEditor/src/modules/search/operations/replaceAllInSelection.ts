import { SearchQuery } from '@codemirror/search';
import { cursorFromQuery } from '../queryCursor';
import SearchOptions from '../options';
import selectedRanges from '../../selection/selectedRanges';

export default function replaceAllInSelection(options: SearchOptions) {
  const cursor = cursorFromQuery(new SearchQuery(options));
  if (cursor === null) {
    return;
  }

  const editor = window.editor;
  const matches = cursor.matchAll(editor.state, 1e9) ?? [];
  if (matches.length === 0) {
    return;
  }

  const changes = matches.map(match => ({
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
