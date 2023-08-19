import { diffLines } from 'diff';

/**
 * Generates diff content like this:
 *
 * {{md-diff-added-n}} This line is new
 * {{md-diff-removed-n}} This line was removed
 *
 * Labels are used to locate the changes and will be hidden visually.
 */
export function generateDiffs(oldValue: string, newValue: string) {
  const parts = diffLines(oldValue, newValue);
  return parts.map(part => {
    const count = part.count;
    const value = part.value;
    if (part.added === true) {
      return `{{md-diff-added-${count}}}${value}`;
    } else if (part.removed === true) {
      return `{{md-diff-removed-${count}}}${value}`;
    } else {
      return value;
    }
  }).join('');
}
