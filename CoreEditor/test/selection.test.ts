import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { EditorView, ViewUpdate } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { editingState } from '../src/common/store';
import { refreshEditFocus } from '../src/modules/selection';

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

describe('refreshEditFocus', () => {
  afterEach(() => {
    window.editor.destroy();
    document.body.innerHTML = '';
    editingState.compositionEnded = true;
  });

  function refresh(allowWhileComposing?: boolean) {
    editor.setUp('Hello');
    const dispatch = jest.spyOn(window.editor, 'dispatch');
    refreshEditFocus(allowWhileComposing);
    return dispatch;
  }

  test('refreshes when no composition is active', () => {
    expect(refresh()).toHaveBeenCalled();
  });

  // E.g., the window becomes key again while marked text is still uncommitted
  test('does not refresh during a composition', () => {
    editingState.compositionEnded = false;
    expect(refresh()).not.toHaveBeenCalled();
  });

  // The invisibles workaround in the input module depends on this
  test('refreshes during a composition when explicitly allowed', () => {
    editingState.compositionEnded = false;
    expect(refresh(true)).toHaveBeenCalled();
  });

  // CodeMirror also observes 'compositionupdate', so it sees compositions our flag misses
  test('does not refresh when only CodeMirror knows about the composition', () => {
    editor.setUp('Hello');
    window.editor.contentDOM.dispatchEvent(new CompositionEvent('compositionstart'));

    const dispatch = jest.spyOn(window.editor, 'dispatch');
    refreshEditFocus();

    expect(window.editor.compositionStarted).toBe(true);
    expect(dispatch).not.toHaveBeenCalled();
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
