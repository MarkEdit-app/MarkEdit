import { describe, expect, test } from '@jest/globals';
import { gutterExtensions } from '../src/styling/nodes/gutter';
import * as editor from '../src/@test/editor';

describe('Styling module', () => {
  test('test CodeMirror class names', async () => {
    editor.setUp('Hello World', [
      ...gutterExtensions,
    ]);

    await sleep(200);
    const elements = [...document.querySelectorAll('*')] as HTMLElement[];

    const classNames = elements.reduce((acc, cur) => {
      [...cur.classList].forEach(cls => acc.add(cls.toString()));
      return acc;
    }, new Set());

    expect(classNames.has('cm-editor')).toBeTruthy();
    expect(classNames.has('cm-focused')).toBeTruthy();
    expect(classNames.has('cm-content')).toBeTruthy();
    expect(classNames.has('cm-scroller')).toBeTruthy();
    expect(classNames.has('cm-gutters')).toBeTruthy();
    expect(classNames.has('cm-gutter')).toBeTruthy();
    expect(classNames.has('cm-gutterElement')).toBeTruthy();
    expect(classNames.has('cm-foldGutter')).toBeTruthy();
    expect(classNames.has('cm-line')).toBeTruthy();
    expect(classNames.has('cm-lineNumbers')).toBeTruthy();
  });
});

function sleep(milliseconds: number) {
  // eslint-disable-next-line compat/compat
  return new Promise(resolve => {
    setTimeout(resolve, milliseconds);
  });
}
