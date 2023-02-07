import { EditorSelection, SelectionRange } from '@codemirror/state';

export default function selectWithRanges(ranges: SelectionRange[]) {
  const editor = window.editor;
  editor.dispatch({
    selection: EditorSelection.create(ranges),
  });
}
