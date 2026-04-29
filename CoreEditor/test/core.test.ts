import { describe, expect, test, beforeEach } from '@jest/globals';
import { EditorSelection } from '@codemirror/state';
import { Config } from '../src/config';
import { performTextDrop, resetEditor } from '../src/core';
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
    const sel = normalizeSelection(doc.length, { anchor: 5, head: 5 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(5);
    expect(sel.head).toBe(5);
  });

  test('valid selection range', () => {
    const sel = normalizeSelection(doc.length, { anchor: 0, head: 5 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(5);
  });

  test('anchor and head exceeding length are clamped', () => {
    const sel = normalizeSelection(doc.length, { anchor: 100, head: 200 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(doc.length);
    expect(sel.head).toBe(doc.length);
  });

  test('negative values are clamped to 0', () => {
    const sel = normalizeSelection(doc.length, { anchor: -10, head: -5 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('mixed out-of-bounds values', () => {
    const sel = normalizeSelection(doc.length, { anchor: -1, head: 100 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(doc.length);
  });

  test('empty document with selection range', () => {
    const sel = normalizeSelection(0, { anchor: 5, head: 10 } as { anchor: CodeGen_Int; head: CodeGen_Int });
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

  test('without selection range, cursor is at 0', () => {
    resetEditor('Hello, World!');
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('with valid selection range', () => {
    resetEditor('Hello, World!', { anchor: 7 as CodeGen_Int, head: 12 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(7);
    expect(sel.head).toBe(12);
  });

  test('with cursor position (anchor equals head)', () => {
    resetEditor('Hello, World!', { anchor: 5 as CodeGen_Int, head: 5 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(5);
    expect(sel.head).toBe(5);
  });

  test('selection range exceeding document length is clamped', () => {
    const content = 'Short';
    resetEditor(content, { anchor: 100 as CodeGen_Int, head: 200 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(content.length);
    expect(sel.head).toBe(content.length);
  });

  test('negative selection range is clamped to 0', () => {
    resetEditor('Hello', { anchor: -5 as CodeGen_Int, head: -1 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('empty document with selection range clamps to 0', () => {
    resetEditor('', { anchor: 10 as CodeGen_Int, head: 20 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('document content is preserved', () => {
    const content = 'Hello, MarkEdit!';
    resetEditor(content, { anchor: 0 as CodeGen_Int, head: 5 as CodeGen_Int });
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

  test('inserts text at the drop cursor position', () => {
    resetEditor('Hello, World!');
    fakeDropCursor(7);

    performTextDrop('there ');
    expect(window.editor.state.doc.toString()).toBe('Hello, there World!');
  });

  test('moves the caret to after the inserted text', () => {
    resetEditor('Hello, World!');
    fakeDropCursor(7);

    performTextDrop('there ');
    expect(window.editor.state.selection.main.head).toBe(13);
  });

  test('falls back to replacing the selection when no drop cursor is present', () => {
    resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    performTextDrop('Earth');
    expect(window.editor.state.doc.toString()).toBe('Hello, Earth!');
  });

  test('falls back when posAtCoords returns null', () => {
    resetEditor('Hello, World!');
    fakeDropCursor(null);
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    performTextDrop('Earth');
    expect(window.editor.state.doc.toString()).toBe('Hello, Earth!');
  });
});
