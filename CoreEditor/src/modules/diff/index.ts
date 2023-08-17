import { diffLines } from 'diff';

export function generateDiff(fromText: string, toText: string) {
  const parts = diffLines(fromText, toText);
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
