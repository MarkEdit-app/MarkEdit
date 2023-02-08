import { KeyBinding } from '@codemirror/view';
import { indentLess, indentMore, insertTab } from '@codemirror/commands';
import { TabKeyBehavior } from './types';
import replaceSelections from '../commands/replaceSelections';

/**
 * Customized tab key behavior.
 */
export const indentationKeymap: KeyBinding[] = [
  {
    key: 'Tab',
    preventDefault: true,
    run: ({ state, dispatch }) => {
      switch (window.config.tabKeyBehavior) {
        case TabKeyBehavior.insertTwoSpaces:
          replaceSelections('  ');
          return true;
        case TabKeyBehavior.insertFourSpaces:
          replaceSelections('    ');
          return true;
        case TabKeyBehavior.indentMore:
          return indentMore({ state, dispatch });
        default:
          return insertTab({ state, dispatch });
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
