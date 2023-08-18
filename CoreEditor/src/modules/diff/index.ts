import { diffLines } from 'diff';

/**
 * Generates diff content like this:
 *
 * {{md-diff-added}} This line is new
 * {{md-diff-removed}} This line was removed
 *
 * Labels are used to locate the changes and will be hidden visually.
 */
export function generateDiffs(oldValue: string, newValue: string) {
  const parts = diffLines(oldValue, newValue);
  return parts.map(part => {
    if (part.added === true) {
      return `{{md-diff-added}}${part.value}`;
    } else if (part.removed === true) {
      return `{{md-diff-removed}}${part.value}`;
    } else {
      return part.value;
    }
  }).join('');
}
