import { SearchQuery } from '@codemirror/search';

export default function matchFromQuery(query: SearchQuery): { from: number; to: number } | null {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const anyQuery = (query as any);
  if (typeof anyQuery.create !== 'function') {
    return null;
  }

  const cursor = anyQuery.create();
  if (typeof cursor.nextMatch !== 'function' || typeof cursor.prevMatch !== 'function') {
    return null;
  }

  const state = window.editor.state;
  const { from, to } = state.selection.main;
  return cursor.nextMatch(state, to, to) ?? cursor.prevMatch(state, from, from);
}
