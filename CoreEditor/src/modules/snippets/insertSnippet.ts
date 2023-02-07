import { snippet } from '@codemirror/autocomplete';

/**
 * Insert snippet with placeholder tokens, it only handles the main selection.
 *
 * @param template Template string as described in https://codemirror.net/docs/ref/#autocomplete.snippet
 */
export default function insertSnippet(template: string, label = '') {
  const editor = window.editor;
  const { from, to } = editor.state.selection.main;

  // Make #{} the last one to be the border
  snippet(template + '#{}')(editor, { label }, from, to);
}
