import { describe, expect, test, beforeEach } from '@jest/globals';
import { EditorSelection } from '@codemirror/state';
import { Config } from '../src/config';
import { performTextDrop, resetEditor } from '../src/core';
import { editingState } from '../src/common/store';
import normalizeSelection from '../src/modules/selection/normalizeSelection';

// Minimal config
window.config = {
  theme: 'github-light',
  typewriterMode: false,
  focusMode: false,
  readOnlyMode: false,
  showLineNumbers: false,
  showActiveLineIndicator: false,
  lineWrapping: false,
  autoCharacterPairs: false,
  lineHeight: 1.5,
  fontSize: 14,
  fontFace: { family: 'monospace' },
  invisiblesBehavior: 'never',
  indentBehavior: 'never',
} as Config;

describe('Selection clamping logic', () => {
  const doc = 'Hello, World!'; // length = 13

  test('no selection range defaults to cursor at 0', () => {
    const sel = normalizeSelection(doc.length);
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('valid cursor position', () => {
    const sel = normalizeSelection(doc.length, { anchor: 5, head: 5 });
    expect(sel.anchor).toBe(5);
    expect(sel.head).toBe(5);
  });

  test('valid selection range', () => {
    const sel = normalizeSelection(doc.length, { anchor: 0, head: 5 });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(5);
  });

  test('anchor and head exceeding length are clamped', () => {
    const sel = normalizeSelection(doc.length, { anchor: 100, head: 200 });
    expect(sel.anchor).toBe(doc.length);
    expect(sel.head).toBe(doc.length);
  });

  test('negative values are clamped to 0', () => {
    const sel = normalizeSelection(doc.length, { anchor: -10, head: -5 });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('mixed out-of-bounds values', () => {
    const sel = normalizeSelection(doc.length, { anchor: -1, head: 100 });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(doc.length);
  });

  test('empty document with selection range', () => {
    const sel = normalizeSelection(0, { anchor: 5, head: 10 });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });
});

describe('resetEditor selection', () => {
  beforeEach(() => {
    // Clean up previous editor
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (typeof window.editor?.destroy === 'function') {
      window.editor.destroy();
    }

    document.body.innerHTML = '';
  });

  test('without selection range, cursor is at 0', async () => {
    await resetEditor('Hello, World!');
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('with valid selection range', async () => {
    await resetEditor('Hello, World!', { anchor: 7, head: 12 });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(7);
    expect(sel.head).toBe(12);
  });

  test('with cursor position (anchor equals head)', async () => {
    await resetEditor('Hello, World!', { anchor: 5, head: 5 });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(5);
    expect(sel.head).toBe(5);
  });

  test('selection range exceeding document length is clamped', async () => {
    const content = 'Short';
    await resetEditor(content, { anchor: 100, head: 200 });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(content.length);
    expect(sel.head).toBe(content.length);
  });

  test('negative selection range is clamped to 0', async () => {
    await resetEditor('Hello', { anchor: -5, head: -1 });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('empty document with selection range clamps to 0', async () => {
    await resetEditor('', { anchor: 10, head: 20 });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('document content is preserved', async () => {
    const content = 'Hello, MarkEdit!';
    await resetEditor(content, { anchor: 0, head: 5 });
    expect(window.editor.state.doc.toString()).toBe(content);
  });
});

describe('performTextDrop', () => {
  beforeEach(() => {
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (typeof window.editor?.destroy === 'function') {
      window.editor.destroy();
    }

    document.body.innerHTML = '';
  });

  // Inject a fake `.cm-dropCursor` element into the editor's scrollDOM so the lookup
  // succeeds, and stub `posAtCoords` to return the desired document position (jsdom
  // doesn't compute layout, so the real method always returns null).
  function fakeDropCursor(pos: number | null) {
    const cursor = document.createElement('div');
    cursor.className = 'cm-dropCursor';
    window.editor.scrollDOM.appendChild(cursor);

    Object.defineProperty(window.editor, 'posAtCoords', {
      configurable: true,
      value: () => pos,
    });
  }

  test('inserts text at the drop cursor position', async () => {
    await resetEditor('Hello, World!');
    fakeDropCursor(7);

    performTextDrop('there ');
    expect(window.editor.state.doc.toString()).toBe('Hello, there World!');
  });

  test('moves the caret to after the inserted text', async () => {
    await resetEditor('Hello, World!');
    fakeDropCursor(7);

    performTextDrop('there ');
    expect(window.editor.state.selection.main.head).toBe(13);
  });

  test('falls back to replacing the selection when no drop cursor is present', async () => {
    await resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    performTextDrop('Earth');
    expect(window.editor.state.doc.toString()).toBe('Hello, Earth!');
  });

  test('falls back when posAtCoords returns null', async () => {
    await resetEditor('Hello, World!');
    fakeDropCursor(null);
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    performTextDrop('Earth');
    expect(window.editor.state.doc.toString()).toBe('Hello, Earth!');
  });
});

describe('resetEditor documentChanged', () => {
  beforeEach(() => {
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (typeof window.editor?.destroy === 'function') {
      window.editor.destroy();
    }

    document.body.innerHTML = '';
  });

  test('same-document reset preserves the live selection', async () => {
    await resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    await resetEditor('Hello, World!', undefined, false);
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(7);
    expect(sel.head).toBe(12);
  });

  test('same-document reset preserves the live selection across content changes', async () => {
    await resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(3, 8) });

    await resetEditor('Hello, MarkEdit!', undefined, false);
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(3);
    expect(sel.head).toBe(8);
  });

  test('same-document reset with zero live caret stays at 0', async () => {
    await resetEditor('Hello');
    await resetEditor('World', undefined, false);
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('same-document reset overrides caller-provided selectionRange with the live caret', async () => {
    await resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(3, 8) });

    await resetEditor('Hello, World!', { anchor: 0, head: 0 }, false);
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(3);
    expect(sel.head).toBe(8);
  });

  test('documentChanged=true ignores the live caret and uses provided range', async () => {
    await resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    await resetEditor('Other content', { anchor: 2, head: 4 }, true);
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(2);
    expect(sel.head).toBe(4);
  });

  test('documentChanged=true with no range defaults to 0 regardless of prior caret', async () => {
    await resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    await resetEditor('New doc', undefined, true);
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('documentChanged defaults to true', async () => {
    await resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    await resetEditor('Hello, World!');
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });
});

describe('resetEditor selection-dependent state', () => {
  beforeEach(() => {
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (typeof window.editor?.destroy === 'function') {
      window.editor.destroy();
    }

    document.body.innerHTML = '';
    editingState.hasSelection = false;
  });

  test('editingState.hasSelection is true after restoring a non-empty selection', async () => {
    await resetEditor('Hello, World!', { anchor: 7, head: 12 });
    expect(editingState.hasSelection).toBe(true);
  });

  test('editingState.hasSelection is false after restoring a cursor', async () => {
    await resetEditor('Hello, World!', { anchor: 5, head: 5 });
    expect(editingState.hasSelection).toBe(false);
  });

  test('editingState.hasSelection is false when no selection range is provided', async () => {
    await resetEditor('Hello, World!');
    expect(editingState.hasSelection).toBe(false);
  });

  test('editingState.hasSelection is reset to false on a subsequent empty-selection reset', async () => {
    await resetEditor('Hello, World!', { anchor: 7, head: 12 });
    expect(editingState.hasSelection).toBe(true);

    await resetEditor('Hello, World!');
    expect(editingState.hasSelection).toBe(false);
  });

  test('reset with restored non-empty selection does not mutate window.config.showActiveLineIndicator', async () => {
    window.config.showActiveLineIndicator = true;
    try {
      await resetEditor('Hello, World!', { anchor: 7, head: 12 });
      expect(window.config.showActiveLineIndicator).toBe(true);
    } finally {
      window.config.showActiveLineIndicator = false;
    }
  });
});
