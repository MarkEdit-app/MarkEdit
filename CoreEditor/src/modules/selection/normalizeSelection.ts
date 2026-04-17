import { EditorSelection } from '@codemirror/state';
import { SelectionRange } from './types';

/**
 * Creates an EditorSelection clamped to valid document bounds.
 */
export default function normalizeSelection(length: number, selectionRange?: SelectionRange) {
  if (selectionRange !== undefined) {
    return EditorSelection.range(
      Math.max(0, Math.min(length, selectionRange.anchor)),
      Math.max(0, Math.min(length, selectionRange.head)),
    );
  }

  return EditorSelection.cursor(0);
}
