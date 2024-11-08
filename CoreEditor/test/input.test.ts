import { describe, expect, test } from '@jest/globals';
import wrapBlock from '../src/modules/input/wrapBlock';
import * as editor from './utils/editor';

describe('Input module', () => {
  test('test wrapBlock', () => {
    editor.setUp('Hello World');
    editor.selectRange(0, 5);

    wrapBlock('~', window.editor);
    expect(editor.getText()).toBe('~Hello~ World');

    wrapBlock('@', window.editor);
    expect(editor.getText()).toBe('~@Hello@~ World');
  });
});
