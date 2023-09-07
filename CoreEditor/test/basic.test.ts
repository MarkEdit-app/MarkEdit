import { describe, expect, test } from '@jest/globals';

describe('Basic test suite', () => {
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
});
