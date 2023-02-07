import { SelectionRange } from '@codemirror/state';
import { SearchQuery } from '@codemirror/search';

export default function rangesFromQuery(query: SearchQuery): SelectionRange[] | undefined {
  // Get RegExpQuery or StringQuery (we have tests to protect this quirk)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const anyQuery = query as any;
  if (typeof anyQuery.create === 'function') {
    return anyQuery.create().matchAll(window.editor.state, 1e9);
  }

  return undefined;
}
