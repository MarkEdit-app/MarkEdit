import { KeyBinding } from '@codemirror/view';
import { indentLess, indentMore, insertTab } from '@codemirror/commands';
import { acceptCompletion as acceptTooltipCompletion } from '@codemirror/autocomplete';
import { syntaxTree } from '@codemirror/language';
import { TabKeyBehavior } from './types';
import { hasTooltipCompletion } from '../completion';
import replaceSelections from '../commands/replaceSelections';

/**
 * Customized tab key behavior.
 */
export const indentationKeymap: KeyBinding[] = [
  {
    key: 'Tab',
    preventDefault: true,
    run: editor => {
      if (hasTooltipCompletion()) {
        acceptTooltipCompletion(editor);
        return true;
      }

      const cursor = editor.state.selection.main.from;
      const tree = syntaxTree(editor.state);

      // Always indent more around list marks
      for (const side of [-1, 0, 1]) {
        const node = tree.resolve(cursor, side as Parameters<typeof tree.resolve>[1]);
        if (node.name === 'ListItem' || node.name === 'ListMark') {
          return indentMore(editor);
        }
      }

      switch (window.config.tabKeyBehavior) {
        case TabKeyBehavior.insertTwoSpaces:
          replaceSelections('  ');
          return true;
        case TabKeyBehavior.insertFourSpaces:
          replaceSelections('    ');
          return true;
        case TabKeyBehavior.indentMore:
          return indentMore(editor);
        case TabKeyBehavior.insertTab:
        case undefined:
        default:
          return insertTab(editor);
      }
    },
  },
  {
    key: 'Shift-Tab',
    preventDefault: true,
    run: indentLess,
  },
];

export type { TabKeyBehavior };
