import { EditorState } from '@codemirror/state';

export function getFootnoteLabels(state: EditorState): string[] {
  return extractLabels(state, /\[(\^[^\]]+)\]/g);
}

export function getReferenceLinkLabels(state: EditorState): string[] {
  return extractLabels(state, /^\[([^^][^\]]*)\]:\s+/gm);
}

function extractLabels(state: EditorState, regexp: RegExp): string[] {
  const doc = state.doc.toString();
  const labels = [...doc.matchAll(regexp)].map(match => match[1]);
  return [...new Set(labels)];
}
