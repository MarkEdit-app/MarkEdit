import { describe, expect, test, afterEach } from '@jest/globals';
import { EditorSelection, EditorState } from '@codemirror/state';
import { filterTransaction } from '../src/modules/input';
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
