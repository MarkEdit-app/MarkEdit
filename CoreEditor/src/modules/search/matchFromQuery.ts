import { SearchQuery } from '@codemirror/search';
import { cursorFromQuery } from './cursorFromQuery';

export default function matchFromQuery(query: SearchQuery): { from: number; to: number } | null {
  const cursor = cursorFromQuery(query);
  if (cursor === null) {
    return null;
  }

  const state = window.editor.state;
  const { from, to } = state.selection.main;
  return cursor.nextMatch(state, to, to) ?? cursor.prevMatch(state, from, from);
}
