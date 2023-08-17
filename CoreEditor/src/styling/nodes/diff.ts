import { Decoration, MatchDecorator } from '@codemirror/view';
import { createDecoPlugin } from '../helper';

const regexp = /{{md-diff-(added|removed)}}/g;
const classPrefix = 'cm-md-diff';

export const renderDiffs = createDecoPlugin(() => {
  const matcher = new MatchDecorator({
    regexp: regexp,
    boundary: /\S/,
    decorate: (add, from, to, match, editor) => {
      const line = editor.state.doc.lineAt(from);

      // Decorate the background
      add(line.from, line.from, Decoration.line({
        class: `${classPrefix}-${match[1]}`,
      }));

      // Remove the label
      add(from, to, Decoration.replace({}));
    },
  });

  return matcher.createDeco(window.editor);
});
