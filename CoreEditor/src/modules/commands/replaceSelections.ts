import { EditorSelection } from '@codemirror/state';

export default function replaceSelections(replacement: string, selectionMoveBack = 0) {
  const editor = window.editor;
  const updates = editor.state.changeByRange(({ from, to }) => ({
    range: EditorSelection.cursor(from + replacement.length - selectionMoveBack),
    changes: {
      from, to, insert: replacement,
    },
  }));

  editor.dispatch(updates);
}
