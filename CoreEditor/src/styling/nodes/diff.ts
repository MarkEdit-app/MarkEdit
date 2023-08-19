import { Decoration, MatchDecorator } from '@codemirror/view';
import { createDecoPlugin } from '../helper';

const regexp = /{{md-diff-(added|removed)-(\d+)}}/g;
const classPrefix = 'cm-md-diff';

/**
 * Highlights diff content like this:
 *
 * {{md-diff-added-n}} This line is new
 * {{md-diff-removed-n}} This line was removed
 *
 * Labels are used to locate the changes and will be hidden visually.
 */
export const highlightDiffs = createDecoPlugin(() => {
  const matcher = new MatchDecorator({
    regexp: regexp,
    boundary: /\S/,
    decorate: (add, from, to, match, editor) => {
      const doc = editor.state.doc;
      const start = doc.lineAt(from).number;
      const end = start + parseInt(match[2]) - 1;

      // Decorate the background for each line
      for (let index = start; index <= end; ++index) {
        const line = doc.line(index);
        add(line.from, line.from, Decoration.line({
          class: `${classPrefix}-${match[1]}`,
        }));

        // Inside the for loop to fit the range order requirement
        if (index == start) {
          // Hide the label visually
          add(from, to, Decoration.replace({}));
        }
      }
    },
  });

  return matcher.createDeco(window.editor);
});
