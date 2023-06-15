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
