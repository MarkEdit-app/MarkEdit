import { describe, expect, test, afterEach } from '@jest/globals';
import { EditorSelection, EditorState } from '@codemirror/state';
import { filterTransaction, observeChanges } from '../src/modules/input';
import { editingState } from '../src/common/store';
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

describe('Composition over-delete clamp', () => {
  afterEach(() => {
    editingState.compositionEnded = true;
    editingState.compositionPosition = undefined;
  });

  function setUpComposing(doc: string, anchor: number) {
    editor.setUp(doc, EditorState.transactionFilter.of(tr => filterTransaction(tr)));
    editingState.compositionEnded = false;
    editingState.compositionPosition = anchor;
  }

  function dispatchCompose(from: number, to: number, insert: string) {
    window.editor.dispatch({
      changes: { from, to, insert },
      selection: EditorSelection.cursor(from + insert.length),
      userEvent: 'input.type.compose',
    });
  }

  test('clamps a change that deletes across the anchor', () => {
    // "**?**" with the caret after the trailing "**"
    setUpComposing('**?**', 5);

    // WebKit over-deletes "?**" (2..5) and inserts "和"
    dispatchCompose(2, 5, '和');

    // Text before the anchor is preserved
    expect(editor.getText()).toBe('**?**和');
    expect(window.editor.state.selection.main.head).toBe(6);
  });

  test('clamps a change entirely before the anchor', () => {
    setUpComposing('**?**', 5);

    // Hypothetical change fully before the anchor (2..4)
    dispatchCompose(2, 4, '和');

    // Collapses to a zero-width insert at the anchor
    expect(editor.getText()).toBe('**?**和');
    expect(window.editor.state.selection.main.head).toBe(6);
  });

  test('leaves a normal forward composition untouched', () => {
    setUpComposing('**?**', 5);

    // Insert at the anchor, not crossing it
    dispatchCompose(5, 5, '和');

    expect(editor.getText()).toBe('**?**和');
  });

  test('does not clamp once composition has ended', () => {
    editor.setUp('**?**', EditorState.transactionFilter.of(tr => filterTransaction(tr)));
    editingState.compositionEnded = true;
    editingState.compositionPosition = 5;

    dispatchCompose(2, 5, '和');

    // Guard inactive: change applies as-is
    expect(editor.getText()).toBe('**和');
  });

  test('does not clamp non-composition edits', () => {
    setUpComposing('**?**', 5);

    window.editor.dispatch({
      changes: { from: 2, to: 5, insert: '和' },
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('**和');
  });
});

describe('Composition bottom pinning', () => {
  afterEach(() => {
    editingState.wasScrolledToBottom = false;
    editingState.compositionEnded = true;
  });

  // jsdom has no layout, mock the scroll metrics and capture scrollTop writes.
  // A real DOM clamps scrollTop to [0, scrollHeight - clientHeight].
  function mockScroller(scrollHeight = 1000, clientHeight = 100) {
    let top = 0;
    const maxTop = scrollHeight - clientHeight;
    const scrollDOM = window.editor.scrollDOM;
    Object.defineProperty(scrollDOM, 'scrollHeight', { configurable: true, get: () => scrollHeight });
    Object.defineProperty(scrollDOM, 'clientHeight', { configurable: true, get: () => clientHeight });
    Object.defineProperty(scrollDOM, 'scrollTop', { configurable: true, get: () => top, set: (value: number) => { top = Math.max(0, Math.min(value, maxTop)); } });
    return () => top;
  }

  function compose(insert: string) {
    window.editor.dispatch({
      changes: { from: window.editor.state.doc.length, insert },
      userEvent: 'input.type.compose',
    });
  }

  test('pins to the bottom on a composition commit', () => {
    editor.setUp('hello', observeChanges());
    const readTop = mockScroller();
    editingState.wasScrolledToBottom = true;
    editingState.compositionEnded = true;

    compose('你好');

    expect(readTop()).toBe(900);
    expect(editingState.wasScrolledToBottom).toBe(false);
  });

  test('keeps pinning while composition is ongoing', () => {
    editor.setUp('hello', observeChanges());
    const readTop = mockScroller();
    editingState.wasScrolledToBottom = true;
    editingState.compositionEnded = false;

    compose('ni');

    expect(readTop()).toBe(900);
    // Flag stays set until the composition commits
    expect(editingState.wasScrolledToBottom).toBe(true);
  });

  test('does not pin when not previously at the bottom', () => {
    editor.setUp('hello', observeChanges());
    const readTop = mockScroller();
    editingState.wasScrolledToBottom = false;

    compose('你好');

    expect(readTop()).toBe(0);
  });

  test('does not pin for non-composition edits', () => {
    editor.setUp('hello', observeChanges());
    const readTop = mockScroller();
    editingState.wasScrolledToBottom = true;

    window.editor.dispatch({
      changes: { from: window.editor.state.doc.length, insert: 'x' },
      userEvent: 'input.type',
    });

    expect(readTop()).toBe(0);
    // Flag is untouched by unrelated edits
    expect(editingState.wasScrolledToBottom).toBe(true);
  });
});
