import TextCheckerOptions from './options';

/**
 * Div level text checker settings.
 */
export function update(options: TextCheckerOptions) {
  const contentDOM = window.editor.contentDOM;
  contentDOM.setAttribute('spellcheck', options.spellcheck ? 'true' : 'false');
  contentDOM.setAttribute('autocorrect', options.autocorrect ? 'on' : 'off');

  // Remove attributes to respect system preferences,
  // we don't use EditorView.contentAttributes because it doesn't support removing.
  contentDOM.removeAttribute('autocomplete');
  contentDOM.removeAttribute('autocapitalize');
}

/**
 * Dismiss the existing text checking indicator.
 */
export function dismiss() {
  // There's no official way to do that, this works magically
  window.editor.contentDOM.blur();
  window.editor.contentDOM.focus();
}

export type { TextCheckerOptions };
