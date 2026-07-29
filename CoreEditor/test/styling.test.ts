import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { gutterExtensions } from '../src/styling/nodes/gutter';
import { renderWhitespaceBeforeCaret } from '../src/styling/nodes/invisible';
import { selectedLinesDecoration } from '../src/styling/nodes/selection';
import { InvisiblesBehavior } from '../src/config';
import { editingState } from '../src/common/store';
import { sleep } from './utils/helpers';
import * as editor from './utils/editor';

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

  test('decorate active line immediately for focus mode', async () => {
    editor.setUp('line 1\nline 2', selectedLinesDecoration);
    await sleep(200);

    const selected = document.querySelectorAll('.cm-selectedLineRange');
    expect(selected.length).toBe(1);
  });
});

describe('renderWhitespaceBeforeCaret', () => {
  afterEach(() => {
    editingState.compositionEnded = true;
  });

  async function render() {
    editor.setUp('Hello');
    window.config.invisiblesBehavior = InvisiblesBehavior.always;

    const dispatch = jest.spyOn(window.editor, 'dispatch');
    renderWhitespaceBeforeCaret();
    await sleep(100);

    return dispatch;
  }

  test('refreshes the focus when no composition is active', async () => {
    expect(await render()).toHaveBeenCalled();
  });

  // Space is the conversion key for input methods like Japanese
  test('does not refresh the focus during a composition', async () => {
    editingState.compositionEnded = false;
    expect(await render()).not.toHaveBeenCalled();
  });
});
