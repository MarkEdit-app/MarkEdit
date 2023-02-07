import TextCheckerOptions from './options';

/**
 * Div level text checker settings.
 */
export function update(options: TextCheckerOptions) {
  const contentDiv = document.querySelector('.cm-content');
  if (contentDiv === null) {
    return;
  }

  const toString = (value: boolean) => value ? 'true' : 'false';
  contentDiv.setAttribute('spellcheck', toString(options.spellcheck));
  contentDiv.setAttribute('autocorrect', toString(options.autocorrect));
  contentDiv.setAttribute('autocomplete', toString(options.autocomplete));
  contentDiv.setAttribute('autocapitalize', toString(options.autocapitalize));
}

export type { TextCheckerOptions };
