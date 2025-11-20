import { EditorState } from '@codemirror/state';

export function getFootnoteLabels(state: EditorState): string[] {
  const doc = state.doc.toString();
  const labels = [...doc.matchAll(/\[(\^[^\]]+)\]/g)].map(match => match[1]);
  return [...new Set(labels)];
}
