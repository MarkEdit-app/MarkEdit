import { TextTokenizeAnchor } from './types';

export default function anchorAtPos(pos: number): TextTokenizeAnchor {
  const editor = window.editor;
  const line = editor.state.doc.lineAt(pos);
  const offset = line.from;

  return {
    text: line.text,
    pos: (pos - offset) as CodeGen_Int,
    offset: offset as CodeGen_Int,
  };
}
