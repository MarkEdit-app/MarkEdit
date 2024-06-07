import { EditorSelection } from '@codemirror/state';

export default function replaceSelections(replacement: string) {
  const editor = window.editor;
  const updates = editor.state.changeByRange(({ from, to }) => ({
    range: EditorSelection.cursor(from + replacement.length),
    changes: {
      from, to, insert: replacement,
    },
  }));

  editor.dispatch(updates);
}
