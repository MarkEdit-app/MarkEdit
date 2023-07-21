import { history, undo, redo } from '@codemirror/commands';
import { describe, expect, test } from '@jest/globals';
import { canUndo, canRedo, saveHistory, isContentDirty } from '../src/modules/history';
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

  test('test isContentDirty', () => {
    editor.setUp('Hello World', history());
    expect(isContentDirty()).toBeFalsy();

    editor.insertText('\n');
    expect(isContentDirty()).toBeTruthy();

    undo(window.editor);
    expect(isContentDirty()).toBeFalsy();

    saveHistory();
    expect(isContentDirty()).toBeFalsy();

    editor.insertText('\n');
    editor.insertText('\n');
    expect(isContentDirty()).toBeTruthy();

    saveHistory();
    expect(isContentDirty()).toBeFalsy();

    undo(window.editor);
    expect(isContentDirty()).toBeTruthy();

    redo(window.editor);
    expect(isContentDirty()).toBeFalsy();

    undo(window.editor);
    undo(window.editor);
    expect(isContentDirty()).toBeTruthy();
  });
});
