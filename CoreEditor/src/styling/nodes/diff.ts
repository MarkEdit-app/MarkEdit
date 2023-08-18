import { Decoration, MatchDecorator } from '@codemirror/view';
import { createDecoPlugin } from '../helper';

const regexp = /{{md-diff-(added|removed)}}/g;
const classPrefix = 'cm-md-diff';

/**
 * Highlights diff content like this:
 *
 * {{md-diff-added}} This line is new
 * {{md-diff-removed}} This line was removed
 *
 * Labels are used to locate the changes and will be hidden visually.
 */
export const highlightDiffs = createDecoPlugin(() => {
  const matcher = new MatchDecorator({
    regexp: regexp,
    boundary: /\S/,
    decorate: (add, from, to, match, editor) => {
      const line = editor.state.doc.lineAt(from);

      // Decorate the background
      add(line.from, line.from, Decoration.line({
        class: `${classPrefix}-${match[1]}`,
      }));

      // Hide the label visually
      add(from, to, Decoration.replace({}));
    },
  });

  return matcher.createDeco(window.editor);
});
