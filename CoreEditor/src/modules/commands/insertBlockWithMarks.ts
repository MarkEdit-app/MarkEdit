import { EditorSelection } from '@codemirror/state';

/**
 * Generally used to insert blocks like fenced code.
 */
export default function insertBlockWithMarks(marks: string) {
  const editor = window.editor;
  const lineBreak = editor.state.lineBreak;

  const updates = editor.state.changeByRange(({ from, to }) => {
    const line = editor.state.doc.lineAt(from);
    const selected = editor.state.sliceDoc(from, to);
    const prefix = line.from === from ? '' : lineBreak;
    const suffix = line.to === to ? '' : lineBreak;

    // Replace with the updated content and keep the original selection
    const insert = `${prefix}${marks}${lineBreak}${selected}${lineBreak}${marks}${suffix}`;
    const anchor = from + prefix.length + marks.length + lineBreak.length;
    const head = anchor + selected.length;

    return {
      range: EditorSelection.range(anchor, head),
      changes: { from, to, insert },
    };
  });

  editor.dispatch(updates);
}
