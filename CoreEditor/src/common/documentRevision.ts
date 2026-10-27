import { EditorState, Text } from '@codemirror/state';

let revisions: WeakMap<Text, { lineBreak: string; revision: string }> | undefined;

export function getDocumentRevision(state: EditorState): string {
  revisions ??= new WeakMap();
  const cached = revisions.get(state.doc);
  if (cached?.lineBreak === state.lineBreak) {
    return cached.revision;
  }

  const revision = crypto.randomUUID();
  revisions.set(state.doc, { lineBreak: state.lineBreak, revision });
  return revision;
}
