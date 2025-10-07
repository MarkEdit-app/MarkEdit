import { KeyBinding } from '@codemirror/view';
import { indentLess, indentMore, insertTab } from '@codemirror/commands';
import { acceptCompletion as acceptTooltipCompletion } from '@codemirror/autocomplete';
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

      switch (window.config.tabKeyBehavior) {
        case TabKeyBehavior.insertTwoSpaces:
          replaceSelections('  ');
          return true;
        case TabKeyBehavior.insertFourSpaces:
          replaceSelections('    ');
          return true;
        case TabKeyBehavior.indentMore:
          return indentMore(editor);
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
