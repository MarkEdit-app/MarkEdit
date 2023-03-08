import { EditorSelection } from '@codemirror/state';
import { TextTokenizeAnchor } from './types';
import anchorAtPos from './anchorAtPos';

/**
 * For double-click, leverage native methods to tokenize the selection.
 */
export async function handleDoubleClick(event: MouseEvent) {
  const editor = window.editor;
  const pos = tokenizePosition(event);
  if (pos === null) {
    return;
  }

  const line = editor.state.doc.lineAt(pos);
  const anchor = anchorAtPos(pos);

  // On Apple platforms, this eventually leverages NLTokenizer
  const result = await window.nativeModules.tokenizer.tokenize({ anchor });
  const from = result.from + line.from;
  const to = result.to + line.from;

  editor.dispatch({
    // We would like to add a new selection instead of just replace the existing one,
    // this is important for multi-selection scenarios.
    //
    // Also, we need to filter out ranges that creates a selection with two carets.
    selection: EditorSelection.create([
      ...editor.state.selection.ranges.filter(range => range.to < from || range.from > to),
      EditorSelection.range(from, to),
    ]),
  });
}

/**
 * Handle option-arrow keys, leverage native methods to move by word.
 */
export async function handleKeyDown(event: KeyboardEvent) {
  const editor = window.editor;
  const state = editor.state;

  // Tokenization based moving is more meaningful for single selection
  if (!event.altKey || state.selection.ranges.length > 1) {
    return;
  }

  const moveWord = async(moveFn: ({ anchor }: { anchor: TextTokenizeAnchor }) => Promise<CodeGen_Int>) => {
    event.preventDefault();
    event.stopPropagation();

    const newPos = await moveFn({ anchor: anchorAtPos(pos) });
    editor.dispatch({
      selection: EditorSelection.cursor(newPos),
    });
  };

  const pos = state.selection.main.head;
  const line = state.doc.lineAt(pos);

  // We don't leverage the tokenizer if it's at the start of a line
  if (event.key === 'ArrowLeft' && line.from !== pos) {
    return moveWord(window.nativeModules.tokenizer.moveWordBackward);
  }

  // We don't leverage the tokenizer if it's at the end of a line
  if (event.key === 'ArrowRight' && line.to !== pos) {
    return moveWord(window.nativeModules.tokenizer.moveWordForward);
  }
}

/**
 * Returns the position to tokenize for a mouse event, or null if not applicable.
 */
export function tokenizePosition(event: MouseEvent) {
  // Only for double-click
  if (event.detail !== 2) {
    return null;
  }

  const editor = window.editor;
  const pos = editor.posAtCoords({ x: event.clientX, y: event.clientY });
  if (pos === null) {
    return null;
  }

  // We don't caret about ascii characters, tokenization is more meaningful for CJK languages.
  const character = editor.state.doc.sliceString(pos, pos + 1);
  if (/[ -~]/.test(character)) {
    return null;
  }

  return pos;
}
