import { SearchQuery } from '@codemirror/search';
import { EditorState } from '@codemirror/state';

export interface QueryResult {
  from: number;
  to: number;
}

export interface QueryCursor {
  matchAll: (state: EditorState, limit: number) => QueryResult[] | null;
  getReplacement: (result: QueryResult) => string;
  nextMatch: (state: EditorState, from: number, to: number) => QueryResult | null;
  prevMatch: (state: EditorState, from: number, to: number) => QueryResult | null;
}

export function cursorFromQuery(query: SearchQuery) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const anyQuery = (query as any);
  if (typeof anyQuery.create !== 'function') {
    return null;
  }

  const cursor = anyQuery.create();
  if ([cursor.matchAll, cursor.getReplacement, cursor.nextMatch, cursor.prevMatch].some($ => typeof $ !== 'function')) {
    return null;
  }

  return cursor as QueryCursor;
}
