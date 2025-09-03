import { ChangeSpec } from '@codemirror/state';
import { getEditorText } from '../../core';

/**
 * Format the content, usually gets called when saving files.
 *
 * @param insertFinalNewline Whether to insert newline at end of file
 * @param trimTrailingWhitespace Whether to remove trailing whitespaces
 * @param userInitiated Whether the action is explicitly triggered by the user
 */
export default function formatContent(
  insertFinalNewline: boolean,
  trimTrailingWhitespace: boolean,
  userInitiated: boolean,
) {
  const editor = window.editor;
  const state = editor.state;

  const apply = (changes: ChangeSpec) => {
    editor.dispatch({
      changes,
      userEvent: '@none', // Ignore automatic scrolling
    });
  };

  if (insertFinalNewline) {
    // We don't need to ensure final newline when it's empty
    const text = getEditorText();
    if (text.length > 0 && !text.endsWith(state.lineBreak)) {
      apply({
        insert: state.lineBreak,
        from: state.doc.length,
      });
    }
  }

  if (trimTrailingWhitespace) {
    // We need to update reversely to avoid index shift
    for (let index = state.doc.lines; index >= 1; --index) {
      const line = state.doc.line(index);
      const ranges = state.selection.ranges;

      // For implicit formatting, avoid trimming spaces before the caret
      if (!userInitiated && ranges.some(({ from, to }) => from === to && line.to === to)) {
        continue;
      }

      const match = /\s+$/g.exec(line.text);
      if (match !== null) {
        apply({
          insert: '',
          from: match.index + line.from,
          to: line.to,
        });
      }
    }
  }
}
