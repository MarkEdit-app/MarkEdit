import { describe, expect, jest, test } from '@jest/globals';
import { EditorView } from '@codemirror/view';
import { notifyEditorReady, onEditorReady } from '../src/api/methods';

describe('onEditorReady', () => {
  test('notifies later listeners when one throws', () => {
    window.editor = document.createElement('div') as unknown as EditorView;
    const error = new Error('Failed listener');
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    const listener = jest.fn();

    onEditorReady(() => { throw error; });
    onEditorReady(listener);

    const editor = { dispatch() {} } as unknown as EditorView;
    notifyEditorReady(editor);

    expect(consoleError).toHaveBeenCalledWith('Failed to notify an editor-ready listener:', error);
    expect(listener).toHaveBeenCalledWith(editor);
  });

  test('isolates a listener registered after the editor is ready', () => {
    window.editor = { dispatch() {} } as unknown as EditorView;
    const error = new Error('Failed listener');
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});

    expect(() => onEditorReady(() => { throw error; })).not.toThrow();
    expect(consoleError).toHaveBeenCalledWith('Failed to notify an editor-ready listener:', error);
  });
});
