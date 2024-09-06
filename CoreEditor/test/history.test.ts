import { EditorView } from '@codemirror/view';
import { Transaction } from '@codemirror/state';
import { history, undo, redo } from '../src/@vendor/commands/history';
import { describe, expect, test } from '@jest/globals';
import { canUndo, canRedo, markContentClean, isContentDirty } from '../src/modules/history';
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

    markContentClean();
    expect(isContentDirty()).toBeFalsy();

    editor.insertText('\n');
    editor.insertText('\n');
    expect(isContentDirty()).toBeTruthy();

    markContentClean();
    expect(isContentDirty()).toBeFalsy();

    undo(window.editor);
    expect(isContentDirty()).toBeTruthy();

    redo(window.editor);
    expect(isContentDirty()).toBeFalsy();

    undo(window.editor);
    undo(window.editor);
    expect(isContentDirty()).toBeTruthy();
  });

  test('test userEvent for history actions', () => {
    const annotations: (string | undefined) [] = [];
    editor.setUp('Hello World', [history(), EditorView.updateListener.of(update => {
      annotations.push(...update.transactions.map(tr => tr.annotation(Transaction.userEvent)));
    })]);

    editor.insertText('\n');
    editor.insertText('\n');
    undo(window.editor);
    redo(window.editor);

    expect(annotations).toContain('undo');
    expect(annotations).toContain('redo');
  });
});
