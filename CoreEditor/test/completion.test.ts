import { completionKeymap } from '@codemirror/autocomplete';
import { describe, expect, test } from '@jest/globals';

describe('Completion keymap', () => {
  test('uses the expected navigation keys', () => {
    const navigationBindings = completionKeymap.filter(binding =>
      /^(Arrow|Page)(Up|Down)$/.test(binding.key ?? ''),
    );

    expect(navigationBindings.map(binding => binding.key).sort()).toEqual([
      'ArrowDown',
      'ArrowUp',
      'PageDown',
      'PageUp',
    ]);

    expect(navigationBindings.every(binding => binding.run !== undefined)).toBe(true);
  });
});
