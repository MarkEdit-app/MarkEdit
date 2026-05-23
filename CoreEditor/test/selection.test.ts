import { afterEach, describe, expect, test } from '@jest/globals';
import { EditorView, ViewUpdate } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';

import * as editor from './utils/editor';
import selectionChanged from '../src/modules/selection/selectionChanged';

describe('selectionChanged', () => {
  afterEach(() => {
    window.editor.destroy();
    document.body.innerHTML = '';
  });

  test('true when selection moves to a different position', () => {
    const update = captureUpdate(() => {
      window.editor.dispatch({ selection: EditorSelection.cursor(3) });
    });
    expect(selectionChanged(update)).toBe(true);
  });

  test('false when re-dispatching the current selection (refreshEditFocus pattern)', () => {
    const update = captureUpdate(() => {
      window.editor.dispatch({
        selection: window.editor.state.selection,
        userEvent: 'select',
      });
    });
    expect(update.selectionSet).toBe(true);
    expect(selectionChanged(update)).toBe(false);
  });

  test('false when no selection spec is dispatched', () => {
    const update = captureUpdate(() => {
      window.editor.dispatch({ changes: { from: 0, insert: '!' } });
    });
    expect(update.selectionSet).toBe(false);
    expect(selectionChanged(update)).toBe(false);
  });
});

function captureUpdate(action: () => void): ViewUpdate {
  let captured: ViewUpdate | undefined;
  const listener = EditorView.updateListener.of(update => { captured = update; });
  editor.setUp('Hello World', listener);
  action();

  if (captured === undefined) {
    throw new Error('No ViewUpdate captured');
  }

  return captured;
}
