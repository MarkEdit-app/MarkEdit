import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { EditorView, ViewUpdate } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { editingState } from '../src/common/store';
import { refreshEditFocus, selectWholeDocument } from '../src/modules/selection';

import * as editor from './utils/editor';
import selectionChanged from '../src/modules/selection/selectionChanged';

describe('selectWholeDocument', () => {
  let nestedEditor: EditorView | undefined;

  afterEach(() => {
    nestedEditor?.destroy();
    nestedEditor = undefined;
    window.editor.destroy();
    document.body.innerHTML = '';
  });

  function setUpCell(doc = 'Table cell') {
    editor.setUp('Main document');
    const widget = document.createElement('div');
    widget.contentEditable = 'false';
    window.editor.contentDOM.appendChild(widget);
    nestedEditor = new EditorView({ doc, parent: widget });
    return nestedEditor;
  }

  test('selects the full main document when it has focus', () => {
    editor.setUp('Main document');
    selectWholeDocument();
    expect(window.editor.state.selection.main).toEqual(EditorSelection.range(0, 13));
  });

  test('selects only the focused nested editor', () => {
    const cell = setUpCell();
    cell.focus();
    selectWholeDocument();
    expect(cell.state.selection.main).toEqual(EditorSelection.range(0, 10));
    expect(window.editor.state.selection.main.empty).toBe(true);
    expect(cell.hasFocus).toBe(true);
  });

  test('keeps an empty cell focused without selecting the main document', () => {
    const cell = setUpCell('');
    cell.focus();
    selectWholeDocument();
    expect(cell.state.selection.main.empty).toBe(true);
    expect(window.editor.state.selection.main.empty).toBe(true);
    expect(cell.hasFocus).toBe(true);
  });

  test('selects the main document after focus returns from a nested editor', () => {
    const cell = setUpCell();
    cell.focus();
    window.editor.focus();
    selectWholeDocument();
    expect(window.editor.state.selection.main).toEqual(EditorSelection.range(0, 13));
    expect(cell.state.selection.main.empty).toBe(true);
  });

  test('does not select an unrelated editor', () => {
    editor.setUp('Main document');
    nestedEditor = new EditorView({ doc: 'Unrelated', parent: document.body });
    nestedEditor.focus();
    selectWholeDocument();
    expect(nestedEditor.state.selection.main.empty).toBe(true);
    expect(window.editor.state.selection.main.empty).toBe(true);
  });

  test('does not select the document when an input inside the editor has focus', () => {
    editor.setUp('Main document');
    const input = document.createElement('input');
    window.editor.dom.appendChild(input);
    input.focus();
    selectWholeDocument();
    expect(window.editor.state.selection.main.empty).toBe(true);
    expect(document.activeElement).toBe(input);
  });
});

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
