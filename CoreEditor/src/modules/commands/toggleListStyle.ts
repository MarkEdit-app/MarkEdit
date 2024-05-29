import { EditorSelection, Line } from '@codemirror/state';
import removeListMarkers from './removeListMarkers';
import * as selection from '../selection';

/**
 * Toggle list style by providing pattern and customizable callbacks.
 *
 * @param matches RegExp that matches a given line
 * @param createMark Function to create the mark
 * @param toggleMark Function to toggle the mark
 */
export default function toggleListStyle(
  matches: (index: number) => RegExp,
  createMark: (index: number, suggested?: string) => string,
  toggleMark?: (line: string) => string | undefined
) {
  const editor = window.editor;
  const selectedRanges = selection.reversedRanges();

  // Iterate multiple lines reversely
  //
  // Ideally we should be using state.changeByRange,
  // but it doesn't work very well with multi-selection x multi-line mixed,
  // here we want to treat each line as an independent update.
  //
  // The downside of this approach is that updates are also reversed.
  for (const { from, to } of selectedRanges) {
    const lines = selection.linesWithRange(from, to);
    const literate = (callback: (match: RegExpMatchArray | null, empty: boolean, line: Line, index: number) => void) => {
      let skipped = 0;
      let index = 0;

      for (; index < lines.length; ++index) {
        const line = lines[index];
        const regex = matches(index - skipped);
        const empty = lines.length > 1 && line.text.length === 0;
        callback(line.text.match(regex), empty, line, index - skipped);

        // Indices for empty lines are skipped
        if (empty) {
          ++skipped;
        }
      }
    };

    let removeMarks = true;
    let suggestedMark: string | undefined = undefined;

    // We are doing two passes, the first one detects the existing structure
    literate((match, empty) => {
      if (match) {
        suggestedMark = match[0].substring(0, 1);
      } else if (!empty) {
        removeMarks = false;
      }
    });

    // The second pass, figures out the actual updates
    const updates: string[] = [];
    const movedBy: number[] = [];

    literate((match, _, line, index) => {
      const text = line.text;
      if (match) {
        if (removeMarks) {
          const toggled = toggleMark ? toggleMark(text) : undefined;
          if (toggled !== undefined) {
            // Toggle between styles
            updates.push(toggled);
            movedBy.push(toggled.length - text.length);
          } else {
            // Remove the marker directly
            const markerLen = match[0].length;
            updates.push(text.substring(markerLen));
            movedBy.push(-markerLen);
          }
        } else {
          // Not changed
          updates.push(text);
        }
      } else if (text.length > 0 || lines.length === 1) {
        // Insert list markers to the front
        const markedText = `${createMark(index, suggestedMark)} ${removeListMarkers(text)}`;
        updates.push(markedText);
        movedBy.push(markedText.length - text.length);
      } else {
        // Not changed
        updates.push(text);
      }
    });

    const startIndex = lines[0].from;
    const endIndex = lines.reverse()[0].to;

    // Dispatch all changes altogether
    editor.dispatch({
      changes: {
        from: startIndex, to: endIndex, insert: updates.join(editor.state.lineBreak),
      },
    });

    // Shift selections to ensure that the selected text remains unchanged
    const anchor = from + (movedBy.length > 0 ? movedBy[0] : 0);
    const head = to + movedBy.reduce((a, b) => a + b);

    // The shifted range can be invalid, e.g., negative positions
    if (anchor >= 0 && head <= editor.state.doc.length) {
      editor.dispatch({
        selection: EditorSelection.range(anchor, head),
      });
    }
  }
}
