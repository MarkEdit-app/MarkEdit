import { EditorSelection, EditorState } from '@codemirror/state';
import { EditorView } from '@codemirror/view';
import { syntaxTree } from '@codemirror/language';
import { SyntaxNode } from '@lezer/common';
import insertSnippet from '../snippets/insertSnippet';

const mark = '`';
const pair = mark.repeat(2);
const fence = mark.repeat(3);

/**
 * Handle the backtick key: expand two preceding backticks into a code block,
 * otherwise wrap the selection or insert a single backtick.
 */
export default function insertCodeBlock(editor: EditorView) {
  const state = editor.state;
  const doc = state.doc;
  const { from } = state.selection.main;

  // Insert a code block, always placing it on its own lines
  if (shouldInsertCodeBlock(state, from)) {
    const line = doc.lineAt(from);
    const lineBreak = state.lineBreak;

    // Break out surrounding text so the fences never share a line with other content
    const leading = doc.sliceString(line.from, from - 2).trim() === '' ? '' : lineBreak;
    const trailing = doc.sliceString(from, line.to).trim() === '' ? '' : lineBreak;

    // Replace the two existing backticks so the opening fence can start on its own line
    insertSnippet(
      `${leading}${fence}#{}${lineBreak}#{}${lineBreak}${fence}${trailing}`,
      '',
      { from: from - 2, to: from },
    );

    return true;
  }

  // Wrap the selection, or insert a single backtick for an empty cursor
  editor.dispatch(state.changeByRange(({ from, to }) => {
    const anchor = from + mark.length;
    if (from === to) {
      return {
        range: EditorSelection.cursor(anchor),
        changes: { from, to, insert: mark },
      };
    }

    const selected = state.sliceDoc(from, to);
    return {
      range: EditorSelection.range(anchor, anchor + selected.length),
      changes: { from, to, insert: `${mark}${selected}${mark}` },
    };
  }));

  // Intercepted, default behavior is ignored
  return true;
}

/**
 * A code block is inserted when two backticks precede an empty cursor and we are not already inside code.
 */
function shouldInsertCodeBlock(state: EditorState, pos: number) {
  // Only expand for a single empty selection with room for two preceding backticks.
  // Multiple ranges fall through to the per-range fallback so the backtick isn't dropped.
  if (pos < 2 || state.selection.ranges.length > 1 || !state.selection.main.empty) {
    return false;
  }

  // Requires exactly two backticks right before the cursor
  const doc = state.doc;
  if (doc.sliceString(pos - 2, pos) !== pair) {
    return false;
  }

  // Don't start a new block when the cursor is already inside code
  for (let node: SyntaxNode | null = syntaxTree(state).resolveInner(pos, -1); node !== null; node = node.parent) {
    if (node.name === 'FencedCode' || node.name === 'CodeBlock') {
      return false;
    }

    // Ignore an inline span that our just-typed backticks would open, only bail when truly inside one
    if (node.name === 'InlineCode' && node.from < pos - 2) {
      return false;
    }
  }

  return true;
}
