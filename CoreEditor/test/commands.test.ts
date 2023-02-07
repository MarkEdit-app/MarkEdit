import { describe, expect, test } from '@jest/globals';

import * as editor from '../src/@test/editor';
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
