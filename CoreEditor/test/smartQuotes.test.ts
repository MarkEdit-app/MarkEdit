import { describe, expect, test, afterEach } from '@jest/globals';
import { EditorSelection, StateEffect } from '@codemirror/state';
import { closeBrackets, insertBracket } from '@codemirror/autocomplete';
import { history, redo, undo } from '../src/@vendor/commands/history';
import { smartQuotesHandler } from '../src/modules/smartQuotes';
import * as editor from './utils/editor';

describe('Smart quote closer', () => {
  afterEach(() => window.editor.destroy());

  function setUp(tracked: boolean) {
    editor.setUp('', [
      closeBrackets(),
      smartQuotesHandler,
    ]);

    window.config.autoCharacterPairs = true;
    window.config.smartQuotesEnabled = true;

    if (tracked) {
      const transaction = insertBracket(window.editor.state, '"');
      if (transaction === null) {
        throw new Error('Expected a closing quote transaction');
      }
      window.editor.dispatch(transaction);
    } else {
      window.editor.dispatch({
        changes: { from: 0, insert: '""' },
        selection: EditorSelection.cursor(1),
      });
    }
  }

  function substituteOpeningQuote(text = '', annotated = true) {
    window.editor.dispatch({
      changes: { from: 0, to: 1, insert: `“${text}` },
      selection: EditorSelection.cursor(1 + text.length),
      ...(annotated ? { userEvent: 'input.type' } : {}),
    });
  }

  test('converts a tracked closing quote', () => {
    setUp(true);
    substituteOpeningQuote();

    expect(editor.getText()).toBe('“”');
    expect(window.editor.state.selection.main.head).toBe(1);
  });

  test('converts the closer after delayed substitution', () => {
    setUp(true);
    window.editor.dispatch({
      changes: { from: 1, insert: 's' },
      selection: EditorSelection.cursor(2),
      userEvent: 'input.type',
    });

    window.editor.dispatch({
      changes: { from: 0, to: 1, insert: '“' },
      selection: EditorSelection.cursor(2),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('“s”');
    expect(window.editor.state.selection.main.head).toBe(2);
  });

  test('skips a tracked curly closing quote', () => {
    setUp(true);
    window.editor.dispatch({
      changes: { from: 1, insert: 'h' },
      selection: EditorSelection.cursor(2),
      userEvent: 'input.type',
    });

    window.editor.dispatch({
      changes: { from: 0, to: 1, insert: '“' },
      selection: EditorSelection.cursor(2),
      userEvent: 'input.type',
    });

    window.editor.dispatch({
      changes: { from: 2, insert: '"' },
      selection: EditorSelection.cursor(3),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('“h”');
    expect(window.editor.state.selection.main.head).toBe(3);
  });

  test('does not skip an untracked curly closing quote', () => {
    setUp(false);
    window.editor.dispatch({
      changes: { from: 0, to: 2, insert: '“h”' },
      selection: EditorSelection.cursor(2),
    });

    window.editor.dispatch({
      changes: { from: 2, insert: '"' },
      selection: EditorSelection.cursor(3),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('“h"”');
    expect(window.editor.state.selection.main.head).toBe(3);
  });

  test('does not skip a tracked closer made curly by another edit', () => {
    setUp(true);
    window.editor.dispatch({
      changes: { from: 1, to: 2, insert: '”' },
      selection: EditorSelection.cursor(1),
    });

    window.editor.dispatch({
      changes: { from: 1, insert: '"' },
      selection: EditorSelection.cursor(2),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('""”');
    expect(window.editor.state.selection.main.head).toBe(2);
  });

  test('does not skip a tracked curly quote when Smart Quotes are disabled', () => {
    setUp(true);
    substituteOpeningQuote();

    window.config.smartQuotesEnabled = false;
    window.editor.dispatch({
      changes: { from: 1, insert: '"' },
      selection: EditorSelection.cursor(2),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('“"”');
    expect(window.editor.state.selection.main.head).toBe(2);
  });

  test('converts the closer after typing beyond it', () => {
    setUp(true);
    window.editor.dispatch({ selection: EditorSelection.cursor(2) });

    window.editor.dispatch({
      changes: { from: 2, insert: ' ' },
      selection: EditorSelection.cursor(3),
      userEvent: 'input.type',
    });

    window.editor.dispatch({
      changes: { from: 3, insert: 's' },
      selection: EditorSelection.cursor(4),
      userEvent: 'input.type',
    });

    window.editor.dispatch({
      changes: { from: 0, to: 1, insert: '“' },
      selection: EditorSelection.cursor(4),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('“” s');
    expect(window.editor.state.selection.main.head).toBe(4);
  });

  test('skips untracked quotes before the closer', () => {
    setUp(true);
    window.editor.dispatch({
      changes: { from: 1, insert: '"' },
      selection: EditorSelection.cursor(3),
    });

    window.editor.dispatch({
      changes: { from: 0, to: 1, insert: '“' },
      selection: EditorSelection.cursor(3),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('“"”');
    expect(window.editor.state.selection.main.head).toBe(3);
  });

  test('undoes and redoes both quote conversions together', () => {
    setUp(true);
    window.editor.dispatch({ effects: StateEffect.appendConfig.of(history()) });
    substituteOpeningQuote();

    undo(window.editor);
    expect(editor.getText()).toBe('""');

    redo(window.editor);
    expect(editor.getText()).toBe('“”');
  });

  test('restores converted closer tracking after redo', () => {
    setUp(true);
    window.editor.dispatch({ effects: StateEffect.appendConfig.of(history()) });
    substituteOpeningQuote();
    undo(window.editor);
    redo(window.editor);

    window.editor.dispatch({
      changes: { from: 1, insert: '"' },
      selection: EditorSelection.cursor(2),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('“”');
    expect(window.editor.state.selection.main.head).toBe(2);
  });

  test('converts an asynchronous system substitution', () => {
    setUp(true);
    substituteOpeningQuote('', false);

    expect(editor.getText()).toBe('“”');
    expect(window.editor.state.selection.main.head).toBe(1);
  });

  test('ignores replacements that also insert text', () => {
    setUp(true);
    substituteOpeningQuote('s');

    expect(editor.getText()).toBe('“s"');
    expect(window.editor.state.selection.main.head).toBe(2);
  });

  test('ignores an inserted opening curly quote', () => {
    setUp(true);
    window.editor.dispatch({
      changes: { from: 0, insert: '“' },
      selection: EditorSelection.cursor(2),
      userEvent: 'input.type',
    });

    expect(editor.getText()).toBe('“""');
    expect(window.editor.state.selection.main.head).toBe(2);
  });

  test('leaves an untracked adjacent quote unchanged', () => {
    setUp(false);
    substituteOpeningQuote();

    expect(editor.getText()).toBe('“"');
  });

  test('requires automatic character pairs', () => {
    setUp(true);
    window.config.autoCharacterPairs = false;
    substituteOpeningQuote();

    expect(editor.getText()).toBe('“"');
  });

  test('requires Smart Quotes', () => {
    setUp(true);
    window.config.smartQuotesEnabled = false;
    substituteOpeningQuote();

    expect(editor.getText()).toBe('“"');
  });
});
