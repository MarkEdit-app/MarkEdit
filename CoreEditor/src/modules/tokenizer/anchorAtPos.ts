import { TextTokenizeAnchor } from './types';

/**
 * Returns the line anchor used for text tokenization, based on a position.
 */
export function anchorAtPos(pos: number): TextTokenizeAnchor {
  const editor = window.editor;
  const line = editor.state.doc.lineAt(pos);
  const offset = line.from;

  return {
    text: line.text,
    pos: (pos - offset) as CodeGen_Int,
    offset: offset as CodeGen_Int,
  };
}

/**
 * Returns true when the anchor is valid, we ran into rare cases where string slicing throws exceptions.
 */
export function isValidAnchor(anchor: TextTokenizeAnchor) {
  // The pos at the end of a string is valid and it's the most common case for word completion
  return anchor.pos >= 0 && anchor.pos <= anchor.text.length;
}
