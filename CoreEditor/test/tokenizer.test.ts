import { describe, expect, jest, test } from '@jest/globals';
import { handleDoubleClick, handleKeyDown } from '../src/modules/tokenizer';
import * as editor from './utils/editor';

describe('Tokenizer module', () => {
  test('uses built-in behavior without a native tokenizer', async() => {
    const nativeModules = window.nativeModules;
    Reflect.deleteProperty(window, 'nativeModules');

    try {
      const keyEvent = new KeyboardEvent('keydown', {
        key: 'Backspace',
        altKey: true,
        cancelable: true,
      });

      const mouseEvent = new MouseEvent('dblclick', {
        detail: 2,
        cancelable: true,
      });

      await handleKeyDown(keyEvent);
      await handleDoubleClick(mouseEvent);
      expect(keyEvent.defaultPrevented).toBe(false);
      expect(mouseEvent.defaultPrevented).toBe(false);
    } finally {
      window.nativeModules = nativeModules;
    }
  });

  test('uses built-in behavior with a null native tokenizer', async() => {
    const tokenizer = window.nativeModules.tokenizer;
    window.nativeModules.tokenizer = null as unknown as typeof tokenizer;

    try {
      const event = new KeyboardEvent('keydown', {
        key: 'Backspace',
        altKey: true,
        cancelable: true,
      });

      await handleKeyDown(event);
      expect(event.defaultPrevented).toBe(false);
    } finally {
      window.nativeModules.tokenizer = tokenizer;
    }
  });

  test('keeps the caret at the start after deleting forward', async() => {
    editor.setUp('苹果香蕉葡萄');
    const tokenizer = window.nativeModules.tokenizer;
    window.nativeModules.tokenizer = {
      name: 'tokenizer',
      tokenize: async() => ({}),
      moveWordBackward: async() => 0 as CodeGen_Int,
      moveWordForward: async() => 2 as CodeGen_Int,
    };

    try {
      await handleKeyDown(new KeyboardEvent('keydown', {
        key: 'Delete',
        altKey: true,
        cancelable: true,
      }));

      expect(editor.getText()).toBe('香蕉葡萄');
      expect(window.editor.state.selection.main.head).toBe(0);
    } finally {
      window.nativeModules.tokenizer = tokenizer;
    }
  });

  test('ignores a native deletion result after the editor changes', async() => {
    editor.setUp('苹果香蕉葡萄');
    const tokenizer = window.nativeModules.tokenizer;
    let resolveMove: (position: CodeGen_Int) => void = () => {};

    window.nativeModules.tokenizer = {
      name: 'tokenizer',
      tokenize: async() => ({}),
      moveWordBackward: async() => 0 as CodeGen_Int,
      moveWordForward: () => new Promise(resolve => { resolveMove = resolve; }),
    };

    try {
      const deletion = handleKeyDown(new KeyboardEvent('keydown', {
        key: 'Delete',
        altKey: true,
        cancelable: true,
      }));

      editor.setText('梨');
      resolveMove(2 as CodeGen_Int);
      await deletion;
      expect(editor.getText()).toBe('梨');
    } finally {
      window.nativeModules.tokenizer = tokenizer;
    }
  });

  test('uses built-in deletion when native tokenization fails', async() => {
    editor.setUp('苹果香蕉葡萄');
    const tokenizer = window.nativeModules.tokenizer;
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});

    window.nativeModules.tokenizer = {
      name: 'tokenizer',
      tokenize: async() => ({}),
      moveWordBackward: async() => 0 as CodeGen_Int,
      moveWordForward: async() => { throw new Error('Bridge failed'); },
    };

    try {
      await handleKeyDown(new KeyboardEvent('keydown', {
        key: 'Delete',
        altKey: true,
        cancelable: true,
      }));

      expect(editor.getText()).toBe('');
      expect(consoleError).toHaveBeenCalled();
    } finally {
      consoleError.mockRestore();
      window.nativeModules.tokenizer = tokenizer;
    }
  });
});
