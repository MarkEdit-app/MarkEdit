import formatContent from './formatContent';
import toggleBlockWithMarks from './toggleBlockWithMarks';
import toggleLineLeadingMark from './toggleLineLeadingMark';
import toggleListStyle from './toggleListStyle';
import replaceSelections from './replaceSelections';
import insertBlockWithMarks from './insertBlockWithMarks';

import { EditCommand } from './types';
import * as commands from '@codemirror/commands';

export function toggleBold() {
  toggleBlockWithMarks('**', '**', 'StrongEmphasis', 'EmphasisMark');
}

export function toggleItalic() {
  toggleBlockWithMarks('*', '*', 'Emphasis', 'EmphasisMark');
}

export function toggleStrikethrough() {
  toggleBlockWithMarks('~~', '~~', 'Strikethrough', 'StrikethroughMark');
}

export function toggleInlineCode() {
  toggleBlockWithMarks('`', '`', 'InlineCode', 'CodeMark');
}

export function toggleInlineMath() {
  toggleBlockWithMarks('$', '$');
}

export function toggleHeading(level: number) {
  toggleLineLeadingMark('#', level);
}

export function toggleBlockquote() {
  toggleLineLeadingMark('>', 1);
}

/**
 * Toggle list markers like "- Item", "* Item", or "+ Item".
 */
export function toggleBullet() {
  toggleListStyle(() => /^( *[-*+] )(?! *\[[ xX]\]) */, (_, suggested) => suggested ?? '-');
}

/**
 * Toggle list markers like "1. Item".
 */
export function toggleNumbering() {
  toggleListStyle(index => new RegExp(`^( *${index + 1}\\. )`), index => `${index + 1}.`);
}

/**
 * Toggle list markers like "- [ ] Todo" or "- [x] Done".
 */
export function toggleTodo() {
  toggleListStyle(
    () => /^( *- +\[[ xX]\] +)/,
    () => '- [ ]',
    line => {
      if (!/- +\[ \]/.test(line)) {
        return undefined;
      }

      // Change "- [ ] Item" to "- [x] Item"
      return line.replace(/(- +\[) (\].*)/, '$1x$2');
    }
  );
}

export function insertHorizontalRule() {
  const br = window.editor.state.lineBreak;
  replaceSelections(`${br}---${br}`);
}

export function insertCodeBlock() {
  insertBlockWithMarks('```');
}

export function insertMathBlock() {
  insertBlockWithMarks('$$');
}

/**
 * Wrapper to a series of commands in CodeMirror,
 * we need this because we want to show them in the application.
 */
export function performEditCommand(command: EditCommand) {
  const editor = window.editor;
  switch (command) {
    case EditCommand.indentLess: commands.indentLess(editor); break;
    case EditCommand.indentMore: commands.indentMore(editor); break;
    case EditCommand.selectLine: commands.selectLine(editor); break;
    case EditCommand.moveLineUp: commands.moveLineUp(editor); break;
    case EditCommand.moveLineDown: commands.moveLineDown(editor); break;
    case EditCommand.copyLineUp: commands.copyLineUp(editor); break;
    case EditCommand.copyLineDown: commands.copyLineDown(editor); break;
    case EditCommand.toggleLineComment: commands.toggleComment(editor); break; // Don't call toggleLineComment here, it won't work
    case EditCommand.toggleBlockComment: commands.toggleBlockComment(editor); break;
    default: break;
  }
}

export { formatContent };
export type { EditCommand };
