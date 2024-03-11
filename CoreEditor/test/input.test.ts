import { describe, expect, test } from '@jest/globals';
import { disableMaybeCreateCompositionBarrier } from '../src/common/utils';
import wrapBlock from '../src/modules/input/wrapBlock';
import * as editor from '../src/@test/editor';

describe('Input module', () => {
  test('test disableMaybeCreateCompositionBarrier', () => {
    editor.setUp('Hello');
    expect(disableMaybeCreateCompositionBarrier(window.editor)).toBeTruthy();
  });

  test('test wrapBlock', () => {
    editor.setUp('Hello World');
    editor.selectRange(0, 5);

    wrapBlock('~', window.editor);
    expect(editor.getText()).toBe('~Hello~ World');

    wrapBlock('@', window.editor);
    expect(editor.getText()).toBe('~@Hello@~ World');
  });
});
