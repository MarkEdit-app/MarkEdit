import TextCheckerOptions from './options';

/**
 * Div level text checker settings.
 */
export function updateTextChecker(contentDOM: HTMLElement, options: TextCheckerOptions) {
  contentDOM.setAttribute('spellcheck', options.spellcheck ? 'true' : 'false');
  contentDOM.setAttribute('autocorrect', options.autocorrect ? 'on' : 'off');

  // Remove attributes to respect system preferences,
  // we don't use EditorView.contentAttributes because it doesn't support removing.
  contentDOM.removeAttribute('autocomplete');
  contentDOM.removeAttribute('autocapitalize');
}

export type { TextCheckerOptions };
