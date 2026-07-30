import { LanguageDescription, LanguageSupport } from '@codemirror/language';

/**
 * Code languages shipped with the app, the rest comes from the MarkEdit-language-data extension.
 */
export function bundledLanguages(html: LanguageSupport) {
  return [
    LanguageDescription.of({
      name: 'HTML',
      alias: ['xhtml'],
      extensions: ['html', 'htm', 'handlebars', 'hbs'],
      support: html,
    }),
    LanguageDescription.of({
      name: 'Markdown',
      extensions: ['md', 'markdown', 'mkd'],
      load: async () => (await import('@codemirror/lang-markdown')).markdown(),
    }),
  ];
}
