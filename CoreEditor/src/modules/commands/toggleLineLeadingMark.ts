import { EditorSelection } from '@codemirror/state';
import { reversedLines } from '../selection';

/**
 * Toggle the level of given leading mark, e.g., headings with "#".
 *
 * @param mark The character, such as "#"
 * @param level The length of leading marks
 */
export default function toggleLineLeadingMark(mark: string, level: number) {
  const editor = window.editor;
  const lines = reversedLines();
  const regex = new RegExp(`^( *)(${mark}+)( +)`);

  // Remove all marks only if all lines have exactly the destination level
  const removeMarks = !lines.some(line => {
    const match = line.text.match(regex);
    return match?.[2].length !== level;
  });

  // Iterate multiple lines reversely
  //
  // Ideally we should be using state.changeByRange,
  // but it doesn't work very well with multi-selection x multi-line mixed,
  // here we want to treat each line as an independent update.
  //
  // The downside of this approach is that updates are also reversed.
  for (const line of lines) {
    const replace = (from: number, to: number, insert: string) => {
      editor.dispatch({
        changes: { from, to, insert },
      });
    };

    const text = line.text;
    const match = text.match(regex);
    const repeatedMarks = mark.repeat(level);

    if (match) {
      const from = line.from + match[1].length;
      const markerLen = match[2].length;

      if (markerLen === level) {
        if (removeMarks) {
          // E.g., remove the leading "## "
          replace(from, from + markerLen + match[3].length, '');
        }
      } else {
        // E.g., change "##" to "###"
        replace(from, from + markerLen, repeatedMarks);
      }
    } else if (text.length > 0 || lines.length === 1) {
      // E.g., change "hello" to "## hello"
      replace(line.from, line.from, repeatedMarks + ' ');

      // Place cursor to the end for empty lines
      if (text.length === 0) {
        editor.dispatch({
          selection: EditorSelection.cursor(line.to + repeatedMarks.length + 1),
        });
      }
    }
  }
}
