import { editingState } from '../../common/store';

/**
 * Format the content, usually get called when saving files.
 *
 * @param insertFinalNewline Whether to insert newline at end of file
 * @param trimTrailingWhitespace Whether to remove trailing whitespaces
 */
export default function formatContent(insertFinalNewline: boolean, trimTrailingWhitespace: boolean) {
  const editor = window.editor;
  const state = editor.state;

  if (insertFinalNewline) {
    const text = state.doc.toString();
    if (text.length > 0 && !text.endsWith(state.lineBreak)) {
      editor.dispatch({
        changes: {
          insert: state.lineBreak,
          from: state.doc.length,
        },
      });
    }
  }

  if (trimTrailingWhitespace) {
    // Dirty trick to prevent the "Edited" state change
    editingState.isDirty = true;
    setTimeout(() => editingState.isDirty = false, 50);

    // We need to update reversely to avoid index shift
    for (let index = state.doc.lines; index >= 1; --index) {
      const line = state.doc.line(index);
      const match = /\s+$/g.exec(line.text);
      if (match !== null) {
        const from = match.index + line.from;
        editor.dispatch({
          changes: { insert: '', from, to: line.to },
        });
      }
    }
  }
}
