import { KeyBinding } from '@codemirror/view';
import { insertTab } from '@codemirror/commands';
import { TabKeyBehavior } from './types';
import replaceSelections from '../commands/replaceSelections';

/**
 * Customized tab key behavior.
 */
export const indentationKeymap: KeyBinding[] = [{
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
      default:
        return insertTab({ state, dispatch });
    }
  },
}];

export type { TabKeyBehavior };
