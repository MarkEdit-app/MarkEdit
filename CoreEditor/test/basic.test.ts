import { describe, expect, jest, test } from '@jest/globals';
import { replaceRange } from '../src/common/utils';
import * as utils from '../src/common/utils';
import * as editor from './utils/editor';

describe('Basic test suite', () => {
  test('system beep logs a warning outside release mode', () => {
    const mode = jest.replaceProperty(utils, 'isReleaseMode', false);
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      utils.playSystemBeep('Failed to move history');
      expect(warn).toHaveBeenCalledWith('Invalid operation: Failed to move history (system beep requested in non-release mode)');
    } finally {
      warn.mockRestore();
      mode.restore();
    }
  });

  test('test deduplicate items using Set', () => {
    const deduped = [...new Set([
      'ui-monospace', 'ui-monospace', 'monospace', 'Menlo',
      'system-ui', 'system-ui', 'Helvetica', 'Arial', 'sans-serif',
    ])];

    expect(deduped).toStrictEqual([
      'ui-monospace', 'monospace', 'Menlo',
      'system-ui', 'Helvetica', 'Arial', 'sans-serif',
    ]);
  });

  test('test replacing ranges in string', () => {
    expect(replaceRange('Hello, World', 0, 2, '')).toBe('llo, World');
    expect(replaceRange('Hello, World', 7, 12, 'MarkEdit')).toBe('Hello, MarkEdit');
  });

  test('test slicing string with invalid ranges', () => {
    editor.setUp('Hello');
    const state = window.editor.state;

    expect(state.sliceDoc(-1, 0)).toBe('');
    expect(state.sliceDoc(-1, 1)).toBe('H');
    expect(state.sliceDoc(0, -1000)).toBe('');
    expect(state.sliceDoc(0, 10000)).toBe('Hello');
  });
});
