import { SearchQuery } from '@codemirror/search';
import { EditorState } from '@codemirror/state';

export interface QueryResult {
  from: number;
  to: number;
}

export interface QueryCursor {
  matchAll: (state: EditorState, limit: number) => QueryResult[] | null;
  nextMatch: (state: EditorState, from: number, to: number) => QueryResult | null;
  prevMatch: (state: EditorState, from: number, to: number) => QueryResult | null;
  getReplacement: (result: QueryResult) => string;
}

export function cursorFromQuery(query: SearchQuery) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const anyQuery = query as any;
  if (typeof anyQuery.create !== 'function') {
    return null;
  }

  const cursor = anyQuery.create();
  if (typeof cursor !== 'object') {
    return null;
  }

  if ([cursor.matchAll, cursor.nextMatch, cursor.prevMatch, cursor.getReplacement].some($ => typeof $ !== 'function')) {
    return null;
  }

  return cursor as QueryCursor;
}
