import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { EditorSelection, EditorState } from '@codemirror/state';
import { KeyBinding } from '@codemirror/view';
import { acceptCompletion, autocompletion, closeCompletion, completionStatus, startCompletion } from '@codemirror/autocomplete';
import { editingState } from '../src/common/store';
import { observeChanges } from '../src/modules/input';

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

describe('emoji backward deletion', () => {
  const deleteBackward = (text: string, position = text.length) => {
    editor.setUp(text);
    editor.selectRange(position, position);
    return {
      handled: commands.emojiDeletionKeymap[0].run?.(window.editor),
      text: editor.getText(),
    };
  };

  test.each(['0️⃣', '1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣', '6️⃣', '7️⃣', '8️⃣', '9️⃣', '#️⃣', '*️⃣'])(
    'deletes the complete keycap %s',
    emoji => expect(deleteBackward(emoji)).toEqual({ handled: true, text: '' }),
  );

  test.each(['👍🏽', '👩🏽', '☝️🏽', '🧑🏽‍🤝‍🧑🏻', '👩‍❤️‍👨🏽'])(
    'deletes the complete skin-tone emoji %s',
    emoji => expect(deleteBackward(emoji)).toEqual({ handled: true, text: '' }),
  );

  test('deletes the complete subdivision flag', () => {
    const text = 'a🏴󠁧󠁢󠁥󠁮󠁧󠁿b';
    expect(deleteBackward(text, text.length - 1)).toEqual({ handled: true, text: 'ab' });
  });

  test.each(['👨‍👩‍👧‍👦', '❤️', '🇺🇸', 'é', 'a'])(
    'leaves unaffected input %s to CodeMirror',
    text => expect(deleteBackward(text)).toEqual({ handled: false, text }),
  );
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

describe('formatContent', () => {
  afterEach(() => {
    window.editor.destroy();
    jest.useRealTimers();
    jest.restoreAllMocks();
    editingState.compositionEnded = true;
  });

  test('formats when no composition is active', () => {
    editor.setUp('Hello  ');
    expect(commands.formatContent(true, true, false)).toBe(true);
    expect(editor.getText()).toBe('Hello\n');
  });

  test('preserves the viewport while formatting', () => {
    editor.setUp('Hello');
    const scrollSnapshot = jest.spyOn(window.editor, 'scrollSnapshot');
    const dispatch = jest.spyOn(window.editor, 'dispatch');

    expect(commands.formatContent(true, false, false)).toBe(true);
    expect(scrollSnapshot).toHaveBeenCalledTimes(1);
    expect(dispatch).toHaveBeenCalledWith(expect.objectContaining({ effects: expect.anything() }));
  });

  test('leaves the document untouched during a composition', () => {
    editor.setUp('Hello  ');
    editingState.compositionEnded = false;

    expect(commands.formatContent(true, true, false)).toBe(false);
    expect(editor.getText()).toBe('Hello  ');
  });

  const startTableCompletion = async (status: 'pending' | 'active', doc = '|') => {
    jest.useFakeTimers();
    editor.setUp(doc, [observeChanges(), autocompletion({
      override: [context => ({
        from: context.pos,
        options: [{ label: 'Insert table', type: 'table' }],
      })],
    })]);

    editor.selectRange(doc.length, doc.length);
    startCompletion(window.editor);
    if (status === 'active') {
      await jest.advanceTimersByTimeAsync(100);
    }

    expect(completionStatus(window.editor.state)).toBe(status);
  };

  test.each(['pending', 'active'] as const)('defers background formatting during %s completion', async status => {
    await startTableCompletion(status, 'text  \n|');
    const state = window.editor.state;

    expect(commands.formatContent(true, true, false)).toBe(false);
    expect(window.editor.state).toBe(state);
    expect(completionStatus(window.editor.state)).toBe(status);
  });

  test('automatically retries idle formatting after completion closes without an edit', async () => {
    await startTableCompletion('active');
    const notifyIdle = jest.spyOn(window.nativeModules.core, 'notifyEditorDidBecomeIdle').mockImplementation(() => {
      commands.formatContent(true, true, false);
    });

    window.editor.dispatch({ changes: { from: 0, insert: 'text  \n' }, userEvent: '@none' });
    await jest.advanceTimersByTimeAsync(1000);

    window.editor.dispatch({ changes: { from: 0, insert: 'more\n' }, userEvent: '@none' });
    await jest.advanceTimersByTimeAsync(1499);
    expect(notifyIdle).not.toHaveBeenCalled();

    await jest.advanceTimersByTimeAsync(1);
    expect(notifyIdle).toHaveBeenCalledTimes(1);
    expect(editor.getText()).toBe('more\ntext  \n|');
    expect(completionStatus(window.editor.state)).toBe('active');

    closeCompletion(window.editor);
    await jest.advanceTimersByTimeAsync(1499);
    expect(notifyIdle).toHaveBeenCalledTimes(1);
    await jest.advanceTimersByTimeAsync(1);
    expect(notifyIdle).toHaveBeenCalledTimes(2);
    expect(editor.getText()).toBe('more\ntext\n|\n');
  });

  test('waits for reopened completion and coalesces acceptance into one retry', async () => {
    await startTableCompletion('active');
    const notifyIdle = jest.spyOn(window.nativeModules.core, 'notifyEditorDidBecomeIdle').mockImplementation(() => {
      commands.formatContent(true, false, false);
    });
    expect(commands.formatContent(true, false, false)).toBe(false);
    closeCompletion(window.editor);
    await jest.advanceTimersByTimeAsync(500);
    startCompletion(window.editor);
    await jest.advanceTimersByTimeAsync(1500);
    expect(completionStatus(window.editor.state)).toBe('active');
    expect(notifyIdle).not.toHaveBeenCalled();
    expect(editor.getText()).toBe('|');

    expect(acceptCompletion(window.editor)).toBe(true);
    await jest.advanceTimersByTimeAsync(1500);
    expect(notifyIdle).toHaveBeenCalledTimes(1);
    expect(editor.getText()).toBe('|Insert table\n');
  });

  test.each([true, false])('does not retry an old editor after replacement (destroyed: %s)', async destroy => {
    await startTableCompletion('active');
    const notifyIdle = jest.spyOn(window.nativeModules.core, 'notifyEditorDidBecomeIdle');
    expect(commands.formatContent(true, false, false)).toBe(false);
    closeCompletion(window.editor);
    const previousEditor = window.editor;
    if (destroy) {
      previousEditor.destroy();
    }

    editor.setUp('replacement', observeChanges());
    try {
      await jest.advanceTimersByTimeAsync(2000);
      expect(notifyIdle).not.toHaveBeenCalled();
      expect(editor.getText()).toBe('replacement');
    } finally {
      if (!destroy) {
        previousEditor.destroy();
      }
    }
  });

  test('still formats on explicit save while completion is active', async () => {
    await startTableCompletion('active', 'text  \n|');
    expect(commands.formatContent(true, true, true)).toBe(true);
    expect(editor.getText()).toBe('text\n|\n');
    expect(completionStatus(window.editor.state)).toBe(null);
  });
});

describe('page scrolling', () => {
  const runBinding = (key: string) => {
    const binding = commands.customizedCommandsKeymap.find(item => item.key === key) as KeyBinding | undefined;
    return binding?.run?.(window.editor);
  };

  const mockScroller = (clientHeight: number) => {
    editor.setUp('Hello');
    const scroller = window.editor.scrollDOM;
    const calls: ScrollToOptions[] = [];

    // defineProperty to bypass the read-only clientHeight and the overloaded scrollBy signature
    Object.defineProperty(scroller, 'clientHeight', { value: clientHeight, configurable: true });
    Object.defineProperty(scroller, 'scrollBy', {
      value: (options: ScrollToOptions) => calls.push(options),
      configurable: true,
    });

    return calls;
  };

  test('scrolls one page down, leaving the selection untouched', () => {
    const calls = mockScroller(500);
    editor.selectRange(0, 0);

    expect(runBinding('PageDown')).toBe(true);
    expect(calls).toEqual([{ top: 500 - window.editor.defaultLineHeight }]);
    expect(window.editor.state.selection.main.head).toBe(0);
  });

  test('scrolls one page up, leaving the selection untouched', () => {
    const calls = mockScroller(500);
    editor.selectRange(3, 3);

    expect(runBinding('PageUp')).toBe(true);
    expect(calls).toEqual([{ top: -(500 - window.editor.defaultLineHeight) }]);
    expect(window.editor.state.selection.main.head).toBe(3);
  });

  test('scrolls at least one line when the viewport is too short', () => {
    const calls = mockScroller(0);

    expect(runBinding('PageDown')).toBe(true);
    expect(calls).toEqual([{ top: window.editor.defaultLineHeight }]);
  });
});
