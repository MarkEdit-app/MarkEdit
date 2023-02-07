import { lineNumbers } from '@codemirror/view';
import { codeFolding, foldGutter } from '@codemirror/language';

export const gutterExtensions = [
  lineNumbers(),
  codeFolding({ placeholderText: '•••' }),
  foldGutter({ openText: '▼', closedText: '▶︎' }),
];
