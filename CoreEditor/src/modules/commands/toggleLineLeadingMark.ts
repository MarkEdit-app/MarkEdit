import { EditorSelection } from '@codemirror/state';
import * as selection from '../selection';

/**
 * Toggle the level of given leading mark, e.g., headings with "#".
 *
 * @param mark The character, such as "#"
 * @param level The length of leading marks
 */
export default function toggleLineLeadingMark(mark: string, level: number) {
  const editor = window.editor;
  const lines = selection.reversedLines();
  const regex = new RegExp(`^(${mark}+)( +)`);

  // Remove all marks only if all lines have exactly the destination level
  const removeMarks = !lines.some(line => {
    const match = line.text.match(regex);
    return !match || match[1].length !== level;
  });

  // Iterate multiple lines reversely
  //
  // Ideally we should be using state.changeByRange,
  // but it doesn't work very well with multi-selection x multi-line mixed,
  // here we want to treat each line as an independent update.
  //
  // The downside of this approach is that updates are also reversed.
  for (const line of lines) {
    const replace = (replacement: string) => {
      editor.dispatch({
        changes: {
          from: line.from, to: line.to, insert: replacement,
        },
      });
    };

    const text = line.text;
    const match = text.match(regex);
    const repeatedMarks = mark.repeat(level);

    if (match) {
      if (match[1].length === level) {
        if (removeMarks) {
          // E.g., remove the leading "##"
          replace(text.substring(match[0].length));
        }
      } else {
        // E.g., change "##" to "###"
        replace(`${repeatedMarks}${text.substring(match[1].length)}`);
      }
    } else if (text.length > 0 || lines.length === 1) {
      // E.g., change "hello" to "## hello"
      replace(`${repeatedMarks} ${text}`);

      // Place cursor to the end for empty lines
      if (text.length === 0) {
        editor.dispatch({
          selection: EditorSelection.cursor(line.to + repeatedMarks.length + 1),
        });
      }
    }
  }
}
