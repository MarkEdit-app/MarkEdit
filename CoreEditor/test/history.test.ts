import { history, undo, redo } from '@codemirror/commands';
import { describe, expect, test } from '@jest/globals';
import { canUndo, canRedo } from '../src/modules/history';
import * as editor from '../src/@test/editor';

describe('History module', () => {
  test('test canUndo and canRedo', () => {
    editor.setUp('Hello World', history());
    expect(canUndo()).toBeFalsy();
    expect(canRedo()).toBeFalsy();

    editor.setText('Changed...');
    expect(canUndo()).toBeTruthy();
    expect(canRedo()).toBeFalsy();

    undo(window.editor);
    expect(canUndo()).toBeFalsy();
    expect(canRedo()).toBeTruthy();

    redo(window.editor);
    expect(canUndo()).toBeTruthy();
    expect(canRedo()).toBeFalsy();
  });
});
