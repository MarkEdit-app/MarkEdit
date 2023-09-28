import { describe, expect, test } from '@jest/globals';
import { RectangleMarker } from '@codemirror/view';

describe('Layer marker', () => {
  test('test RectangleMarker', () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const rect = new RectangleMarker('marker', 10, 10, 100, 100) as any;
    expect(rect.left).toBe(10);
    expect(rect.top).toBe(10);
    expect(rect.width).toBe(100);
    expect(rect.height).toBe(100);
  });
});
