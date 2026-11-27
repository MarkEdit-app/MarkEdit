import { describe, expect, jest, test } from '@jest/globals';
import { replaceRange } from '../src/common/utils';
import * as utils from '../src/common/utils';

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

  test('test replacing ranges in string', () => {
    expect(replaceRange('Hello, World', 0, 2, '')).toBe('llo, World');
    expect(replaceRange('Hello, World', 7, 12, 'MarkEdit')).toBe('Hello, MarkEdit');
  });
});
