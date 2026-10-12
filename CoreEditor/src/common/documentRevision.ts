import { EditorState, Text } from '@codemirror/state';

const revisions = new WeakMap<Text, { lineBreak: string; revision: string }>();

export function getDocumentRevision(state: EditorState): string {
  const cached = revisions.get(state.doc);
  if (cached?.lineBreak === state.lineBreak) {
    return cached.revision;
  }

  const revision = crypto.randomUUID();
  revisions.set(state.doc, { lineBreak: state.lineBreak, revision });
  return revision;
}
