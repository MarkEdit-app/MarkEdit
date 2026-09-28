import { afterEach, beforeEach, describe, expect, jest, test } from '@jest/globals';
import { Decoration, EditorView, WidgetType } from '@codemirror/view';
import { markdown } from '../src/@vendor/lang-markdown';
import { focusedEditor } from '../src/common/utils';
import { getEditorState } from '../src/core';
import { performEditCommand } from '../src/modules/commands';
import { EditCommand } from '../src/modules/commands/types';
import { getRect } from '../src/modules/selection';
import { showContextMenu } from '../src/api/ui';
import * as editor from './utils/editor';

let cell: EditorView;

beforeEach(() => {
  const widget = document.createElement('div');
  class CellWidget extends WidgetType {
    toDOM() {
      return widget;
    }
  }

  editor.setUp('Main document with a much longer line', EditorView.decorations.of(Decoration.set([
    Decoration.widget({ widget: new CellWidget() }).range(0),
  ])));

  cell = new EditorView({ doc: 'first\nsecond', parent: widget, extensions: markdown() });
  cell.focus();
});

afterEach(() => {
  jest.useRealTimers();
  jest.restoreAllMocks();
  cell.destroy();
  window.editor.destroy();
  document.body.innerHTML = '';
});

describe('nested editor focus reporting', () => {
  test('reports cell focus and selection rather than the outer selection', () => {
    window.editor.dispatch({ selection: { anchor: 0, head: 4 } });
    expect(focusedEditor()).toBe(cell);
    expect(getEditorState()).toEqual({ hasFocus: true, hasSelection: false });
    cell.dispatch({ selection: { anchor: 0, head: 3 } });
    expect(getEditorState()).toEqual({ hasFocus: true, hasSelection: true });
    window.editor.focus();
    expect(focusedEditor()).toBe(window.editor);
  });

  test('does not treat a text input inside the editor as a focused CodeMirror', () => {
    const input = document.createElement('input');
    cell.dom.appendChild(input);
    input.focus();
    expect(focusedEditor()).toBeNull();
    expect(getEditorState().hasFocus).toBe(false);
  });
});

describe('cell-local selection commands', () => {
  test('Select Line selects the cell line without selecting the Markdown row', () => {
    cell.dispatch({ selection: { anchor: 7 } });
    performEditCommand(EditCommand.selectLine);
    expect(cell.state.sliceDoc(cell.state.selection.main.from, cell.state.selection.main.to)).toBe('second');
    expect(window.editor.state.selection.main.empty).toBe(true);
  });

  test('resets expansion history when commands switch between the root and cell', () => {
    window.editor.focus();
    window.editor.dispatch({ selection: { anchor: 20 } });

    performEditCommand(EditCommand.expandSelection);
    const rootSelection = window.editor.state.selection;
    cell.focus();
    cell.dispatch({ selection: { anchor: 2 } });

    performEditCommand(EditCommand.shrinkSelection);
    expect(cell.state.selection.main.anchor).toBe(2);
    expect(cell.state.selection.main.empty).toBe(true);

    performEditCommand(EditCommand.expandSelection);
    expect(cell.state.selection.main.empty).toBe(false);

    performEditCommand(EditCommand.shrinkSelection);
    expect(cell.state.selection.main.anchor).toBe(2);
    expect(cell.state.selection.main.empty).toBe(true);
    expect(window.editor.state.selection).toBe(rootSelection);

    window.editor.focus();
    performEditCommand(EditCommand.shrinkSelection);
    expect(window.editor.state.selection).toBe(rootSelection);
  });

  test('does not restore stale syntax selections after a cell edit', () => {
    cell.dispatch({ selection: { anchor: 8 } });
    performEditCommand(EditCommand.expandSelection);
    cell.dispatch({ changes: { from: 0, to: cell.state.doc.length, insert: 'x' }, selection: { anchor: 1 } });
    expect(() => performEditCommand(EditCommand.shrinkSelection)).not.toThrow();
    expect(cell.state.selection.main.anchor).toBe(1);
  });

  test('does not restore stale syntax selections after a caret move', () => {
    performEditCommand(EditCommand.expandSelection);
    cell.dispatch({ selection: { anchor: 8 } });
    performEditCommand(EditCommand.shrinkSelection);
    expect(cell.state.selection.main.anchor).toBe(8);
  });

  test('leaves both selections alone while an input has focus', () => {
    const input = document.createElement('input');
    window.editor.dom.appendChild(input);
    input.focus();
    for (const command of [EditCommand.selectLine, EditCommand.expandSelection, EditCommand.shrinkSelection]) {
      performEditCommand(command);
    }

    expect(cell.state.selection.main.empty).toBe(true);
    expect(window.editor.state.selection.main.empty).toBe(true);
    expect(document.activeElement).toBe(input);
  });
});

describe('focused-editor edit commands', () => {
  test.each([
    { command: EditCommand.moveLineUp, anchor: 7, expected: 'second\nfirst' },
    { command: EditCommand.moveLineDown, anchor: 1, expected: 'second\nfirst' },
    { command: EditCommand.copyLineUp, anchor: 7, expected: 'first\nsecond\nsecond' },
    { command: EditCommand.copyLineDown, anchor: 7, expected: 'first\nsecond\nsecond' },
    { command: EditCommand.indentMore, anchor: 7, expected: 'first\n  second' },
  ])('$command changes only the focused cell', ({ command, anchor, expected }) => {
    const rootState = window.editor.state;
    cell.dispatch({ selection: { anchor } });
    performEditCommand(command);
    expect(cell.state.doc.toString()).toBe(expected);
    expect(window.editor.state).toBe(rootState);
    expect(cell.hasFocus).toBe(true);
  });

  test('outdents within the cell', () => {
    const rootState = window.editor.state;
    cell.dispatch({
      changes: { from: 6, insert: '  ' },
      selection: { anchor: 9 },
    });

    performEditCommand(EditCommand.indentLess);
    expect(cell.state.doc.toString()).toBe('first\nsecond');
    expect(window.editor.state).toBe(rootState);
    expect(cell.hasFocus).toBe(true);
  });

  test.each([EditCommand.moveLineUp, EditCommand.moveLineDown])('%s does not move a single-line cell', command => {
    const rootState = window.editor.state;
    cell.dispatch({ changes: { from: 0, to: cell.state.doc.length, insert: 'single' } });
    performEditCommand(command);
    expect(cell.state.doc.toString()).toBe('single');
    expect(window.editor.state).toBe(rootState);
  });

  test.each([EditCommand.toggleLineComment, EditCommand.toggleBlockComment])('%s toggles a comment within the cell', command => {
    const rootState = window.editor.state;
    cell.dispatch({ selection: { anchor: 6, head: 12 } });
    performEditCommand(command);
    expect(cell.state.doc.toString()).toBe('first\n<!-- second -->');
    expect(window.editor.state).toBe(rootState);
    expect(cell.hasFocus).toBe(true);

    performEditCommand(command);
    expect(cell.state.doc.toString()).toBe('first\nsecond');
    expect(window.editor.state).toBe(rootState);
  });

  test('keeps the empty-line comment caret inside the cell comment', () => {
    cell.dispatch({ changes: { from: 0, to: cell.state.doc.length, insert: '' } });
    performEditCommand(EditCommand.toggleLineComment);
    expect(cell.state.doc.toString()).toBe('<!--  -->');
    expect(cell.state.selection.main.anchor).toBe(5);
    expect(cell.hasFocus).toBe(true);
  });

  test.each(Object.values(EditCommand))('%s leaves editors alone when an input has focus', command => {
    const rootState = window.editor.state;
    const cellState = cell.state;
    const input = document.createElement('input');
    window.editor.dom.appendChild(input);
    input.focus();
    performEditCommand(command);

    expect(window.editor.state).toBe(rootState);
    expect(cell.state).toBe(cellState);
    expect(document.activeElement).toBe(input);
  });

  test('keeps root-editor commands working after returning from a cell', () => {
    window.editor.focus();
    performEditCommand(EditCommand.copyLineDown);
    expect(window.editor.state.doc.toString()).toBe('Main document with a much longer line\nMain document with a much longer line');
    expect(cell.state.doc.toString()).toBe('first\nsecond');
    expect(window.editor.hasFocus).toBe(true);
  });
});

describe('context menu caret geometry', () => {
  const cellRect = { left: 80, right: 80, top: 40, bottom: 60 };
  const rootRect = { left: 10, right: 150, top: 20, bottom: 100 };

  function prepareMenu() {
    const show = jest.fn();
    jest.spyOn(document.documentElement, 'clientWidth', 'get').mockReturnValue(window.innerWidth);
    jest.replaceProperty(window, 'nativeModules', {
      ...window.nativeModules,
      api: { ...window.nativeModules.api, showContextMenu: show },
    });

    jest.spyOn(cell, 'coordsAtPos').mockReturnValue(cellRect);
    jest.spyOn(window.editor, 'coordsAtPos').mockReturnValue(rootRect);
    jest.spyOn(window.editor.scrollDOM, 'getBoundingClientRect').mockReturnValue(new DOMRect(0, 0, 200, 200));

    return show;
  }

  test('anchors default menus to the active cell while explicit document coordinates remain root-local', () => {
    jest.useFakeTimers();
    const show = prepareMenu();
    showContextMenu([]);
    expect(show).not.toHaveBeenCalled();
    jest.advanceTimersByTime(50);
    expect(show).toHaveBeenCalledWith({ items: [], location: { x: 80, y: 70 } });
    expect(getRect(0)).toMatchObject({ x: 10, y: 20 });
  });

  test('keeps explicit menu positions unchanged and does not scroll', () => {
    const show = prepareMenu();
    const dispatch = jest.spyOn(cell, 'dispatch');
    showContextMenu([], { x: 1, y: 2 });
    expect(show).toHaveBeenCalledWith({ items: [], location: { x: 1, y: 2 } });
    expect(dispatch).not.toHaveBeenCalled();
  });

  test('falls back to document geometry when no editor has focus', () => {
    jest.useFakeTimers();
    const show = prepareMenu();
    cell.contentDOM.blur();
    showContextMenu([]);
    jest.advanceTimersByTime(50);
    expect(show).toHaveBeenCalledWith({ items: [], location: { x: 10, y: 110 } });
  });

  test('scrolls the cell caret before measuring a menu outside the viewport', () => {
    jest.useFakeTimers();
    const show = prepareMenu();
    jest.spyOn(cell, 'coordsAtPos').mockReturnValue({ ...cellRect, top: 300, bottom: 320 });
    const dispatch = jest.spyOn(cell, 'dispatch');
    showContextMenu([]);
    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(show).not.toHaveBeenCalled();

    jest.spyOn(cell, 'coordsAtPos').mockReturnValue(cellRect);
    jest.advanceTimersByTime(50);
    expect(show).toHaveBeenCalledWith({ items: [], location: { x: 80, y: 70 } });
  });

  test.each([
    { axis: 'vertical', caret: { left: 20, right: 20, top: 100, bottom: 120 } },
    { axis: 'horizontal', caret: { left: 100, right: 100, top: 10, bottom: 30 } },
  ])('scrolls for $axis clipping inside the outer viewport', ({ caret }) => {
    jest.useFakeTimers();
    const show = prepareMenu();
    jest.spyOn(cell.scrollDOM, 'getBoundingClientRect').mockReturnValue(new DOMRect(0, 0, 40, 40));
    const coords = jest.spyOn(cell, 'coordsAtPos').mockReturnValue(caret);
    const effect = EditorView.scrollIntoView(cell.state.selection.main.head, { x: 'nearest', y: 'nearest' });
    const scroll = jest.spyOn(EditorView, 'scrollIntoView').mockReturnValue(effect);
    const dispatch = jest.spyOn(cell, 'dispatch');

    showContextMenu([]);
    expect(scroll).toHaveBeenCalledWith(cell.state.selection.main.head, { x: 'nearest', y: 'nearest' });
    expect(dispatch).toHaveBeenCalledWith({ effects: effect });
    expect(show).not.toHaveBeenCalled();

    coords.mockReturnValue({ left: 20, right: 20, top: 10, bottom: 30 });
    jest.advanceTimersByTime(50);
    expect(show).toHaveBeenCalledWith({ items: [], location: { x: 20, y: 40 } });
  });
});
