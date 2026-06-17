import { snippet } from '@codemirror/autocomplete';

/**
 * Insert snippet with placeholder tokens, it only handles the main selection.
 *
 * @param template Template string as described in https://codemirror.net/docs/ref/#autocomplete.snippet
 * @param range Text range to replace, defaults to the main selection
 */
export default function insertSnippet(template: string, label = '', range?: { from: number; to: number }) {
  const editor = window.editor;
  const { from, to } = range ?? editor.state.selection.main;

  // Make #{} the last one to be the border
  snippet(template + '#{}')(editor, { label }, from, to);
}
