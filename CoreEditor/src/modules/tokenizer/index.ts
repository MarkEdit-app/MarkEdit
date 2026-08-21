import { EditorSelection } from '@codemirror/state';
import { deleteGroupBackward, deleteGroupForward } from '@codemirror/commands';
import { TextTokenizeAnchor } from './types';
import { anchorAtPos } from './anchorAtPos';
import { isReleaseMode } from '../../common/utils';
import selectWithRanges from '../selection/selectWithRanges';

/**
 * For double-click, leverage native methods to tokenize the selection.
 */
export async function handleDoubleClick(event: MouseEvent) {
  if (!hasNativeTokenizer()) {
    return;
  }

  const editor = window.editor;
  const pos = tokenizePosition(event);
  if (pos === null) {
    return;
  }

  const line = editor.state.doc.lineAt(pos);
  const anchor = anchorAtPos(pos);

  // Defensive fix for string slicing issue
  if (anchor.pos < 0 && anchor.pos >= anchor.text.length) {
    return console.error(`Invalid anchor at pos: ${pos}`);
  }

  // On Apple platforms, this eventually leverages NLTokenizer
  const result: { from: number; to: number } = await window.nativeModules.tokenizer.tokenize({ anchor });
  const from = result.from + line.from;
  const to = result.to + line.from;

  // We would like to add a new selection instead of just replace the existing one,
  // this is important for multi-selection scenarios.
  //
  // Also, we need to filter out ranges that creates a selection with two carets.
  selectWithRanges([
    ...editor.state.selection.ranges.filter(range => range.to < from || range.from > to),
    EditorSelection.range(from, to),
  ]);
}

/**
 * Handle option-arrow keys, leverage native methods to move by word.
 */
export async function handleKeyDown(event: KeyboardEvent) {
  if (!hasNativeTokenizer()) {
    return;
  }

  const editor = window.editor;
  const state = editor.state;

  // Tokenization based moving is more meaningful for single selection
  if (!event.altKey || state.selection.ranges.length > 1) {
    return;
  }

  const anchor = state.selection.main.anchor;
  const head = state.selection.main.head;
  const line = state.doc.lineAt(anchor);

  const moveWord = async(moveFn: ({ anchor }: { anchor: TextTokenizeAnchor }) => Promise<CodeGen_Int>) => {
    event.preventDefault();
    event.stopPropagation();

    const newPos = await moveFn({ anchor: anchorAtPos(head) });
    editor.dispatch({
      // When shift key is held, extending the selection rather than moving the caret position
      selection: event.shiftKey ? EditorSelection.range(anchor, newPos) : EditorSelection.cursor(newPos),
      scrollIntoView: true,
    });
  };

  const deleteWord = async(
    moveFn: ({ anchor }: { anchor: TextTokenizeAnchor }) => Promise<CodeGen_Int>,
    direction: 'backward' | 'forward',
  ) => {
    event.preventDefault();
    event.stopPropagation();

    const contextChanged = () => {
      return window.editor !== editor || editor.state !== state;
    };

    try {
      const newPos = await moveFn({ anchor: anchorAtPos(head) });
      if (contextChanged()) {
        return;
      }

      const from = Math.min(head, newPos);
      editor.dispatch({
        changes: { from, to: Math.max(head, newPos) },
        selection: EditorSelection.cursor(from),
        scrollIntoView: true,
        userEvent: `delete.${direction}`,
      });
    } catch (error) {
      if (!contextChanged()) {
        const fallback = direction === 'backward' ? deleteGroupBackward : deleteGroupForward;
        fallback(editor);
      }

      console.error('Native word deletion failed:', error);
    }
  };

  // We don't leverage the tokenizer if it's at the start of a line
  if (event.key === 'ArrowLeft' && line.from !== anchor && !useBuiltIn(anchor - 1)) {
    return moveWord(window.nativeModules.tokenizer.moveWordBackward);
  }

  // We don't leverage the tokenizer if it's at the end of a line
  if (event.key === 'ArrowRight' && line.to !== head && !useBuiltIn(anchor)) {
    return moveWord(window.nativeModules.tokenizer.moveWordForward);
  }

  if (state.selection.main.empty && event.key === 'Backspace' && line.from !== head && !useBuiltIn(head - 1)) {
    return deleteWord(window.nativeModules.tokenizer.moveWordBackward, 'backward');
  }

  if (state.selection.main.empty && event.key === 'Delete' && line.to !== head && !useBuiltIn(head)) {
    return deleteWord(window.nativeModules.tokenizer.moveWordForward, 'forward');
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

  // Only for editor DOM
  if (!window.editor.dom.contains(event.target as Node)) {
    return null;
  }

  const editor = window.editor;
  const pos = editor.posAtCoords({ x: event.clientX, y: event.clientY });
  if (pos === null || useBuiltIn(pos)) {
    return null;
  }

  return pos;
}

/**
 * Determines whether to use the built-in tokenization behavior.
 */
function useBuiltIn(pos: number) {
  // We don't care about ascii characters, tokenization is more meaningful for languages like Chinese and Japanese.
  const character = window.editor.state.sliceDoc(pos, pos + 1);
  return /[ -~]/.test(character);
}

function hasNativeTokenizer() {
  const nativeModules = Reflect.get(window, 'nativeModules') as typeof window.nativeModules | undefined;
  return isReleaseMode && nativeModules?.tokenizer != null;
}
