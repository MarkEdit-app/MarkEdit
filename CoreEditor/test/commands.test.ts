import { describe, expect, test } from '@jest/globals';
import { EditorSelection, EditorState } from '@codemirror/state';

import * as editor from './utils/editor';
import * as commands from '../src/modules/commands';

describe('Commands module', () => {
  test('test toggleBold', () => {
    editor.setUp('Hello');
    editor.selectRange(0, 2);

    commands.toggleBold();
    expect(editor.getText()).toBe('**He**llo');

    commands.toggleBold();
    expect(editor.getText()).toBe('Hello');
  });

  test('test toggleItalic', () => {
    editor.setUp('Hello');
    editor.selectAll();

    commands.toggleItalic();
    expect(editor.getText()).toBe('*Hello*');

    commands.toggleItalic();
    expect(editor.getText()).toBe('Hello');
  });

  test('test toggleStrikethrough', () => {
    editor.setUp('Hello');
    editor.selectAll();

    commands.toggleStrikethrough();
    expect(editor.getText()).toBe('~~Hello~~');

    commands.toggleStrikethrough();
    expect(editor.getText()).toBe('Hello');
  });

  test('test toggleHeading', () => {
    editor.setUp('Hello');

    commands.toggleHeading(1);
    expect(editor.getText()).toBe('# Hello');

    commands.toggleHeading(2);
    expect(editor.getText()).toBe('## Hello');

    commands.toggleHeading(2);
    expect(editor.getText()).toBe('Hello');
  });

  test('test toggleBlockquote', () => {
    editor.setUp('Hello');

    commands.toggleBlockquote();
    expect(editor.getText()).toBe('> Hello');

    commands.toggleBlockquote();
    expect(editor.getText()).toBe('Hello');
  });

  test('test toggleBullet', () => {
    editor.setUp('Hello');

    commands.toggleBullet();
    expect(editor.getText()).toBe('- Hello');

    editor.setText('* Hello');
    commands.toggleBullet();
    expect(editor.getText()).toBe('Hello');

    editor.setText('+ Hello');
    commands.toggleBullet();
    expect(editor.getText()).toBe('Hello');
  });

  test('test toggleNumbering', () => {
    editor.setUp('Hello');

    commands.toggleNumbering();
    expect(editor.getText()).toBe('1. Hello');

    commands.toggleNumbering();
    expect(editor.getText()).toBe('Hello');

    editor.setText('One\nTwo\nThree');
    editor.selectAll();
    commands.toggleNumbering();
    expect(editor.getText()).toBe('1. One\n2. Two\n3. Three');

    commands.toggleNumbering();
    expect(editor.getText()).toBe('One\nTwo\nThree');
  });

  test('test toggleTodo', () => {
    editor.setUp('Hello');

    commands.toggleTodo();
    expect(editor.getText()).toBe('- [ ] Hello');

    commands.toggleTodo();
    expect(editor.getText()).toBe('- [x] Hello');

    commands.toggleTodo();
    expect(editor.getText()).toBe('Hello');
  });
});

describe('insertCodeBlock command', () => {
  function run(doc: string, ranges: [number, number][]) {
    editor.setUp(doc, EditorState.allowMultipleSelections.of(true));
    window.editor.dispatch({
      selection: EditorSelection.create(ranges.map(([a, b]) => EditorSelection.range(a, b))),
    });

    commands.insertCodeBlock();
    return editor.getText();
  }

  test('inserts an empty block for an empty selection', () => {
    expect(run('', [[0, 0]])).toBe('```\n\n```');
  });

  test('wraps a single-line selection as the block content', () => {
    expect(run('code', [[0, 4]])).toBe('```\ncode\n```');
  });

  test('breaks the fences onto their own lines for a mid-line selection', () => {
    expect(run('abcXYZdef', [[3, 6]])).toBe('abc\n```\nXYZ\n```\ndef');
  });

  test('preserves braces in the selected content', () => {
    expect(run('a{b}c', [[0, 5]])).toBe('```\na{b}c\n```');
  });

  test('preserves backslashes in the selected content', () => {
    expect(run('C:\\path\\', [[0, 8]])).toBe('```\nC:\\path\\\n```');
  });

  test('falls back to plain wrapping for a multi-line selection', () => {
    const out = run('l1\nl2', [[0, 5]]);
    expect(out).not.toContain('#{');
    expect(out).toBe('```\nl1\nl2\n```\n');
  });

  test('falls back to plain wrapping for multiple selections', () => {
    const out = run('ab', [[0, 0], [2, 2]]);
    expect(out).not.toContain('#{');
    expect((out.match(/```/g) ?? []).length).toBe(4);
  });
});
