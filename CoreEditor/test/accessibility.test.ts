import { describe, expect, test } from '@jest/globals';
import { EditorView } from '@codemirror/view';
import * as editor from './utils/editor';

describe('Accessibility test suite', () => {
  test('test contentDOM has role textbox', () => {
    editor.setUp('', EditorView.contentAttributes.of({
      'role': 'textbox',
      'aria-multiline': 'true',
    }));

    const contentDOM = window.editor.contentDOM;
    expect(contentDOM.getAttribute('role')).toBe('textbox');
  });

  test('test contentDOM has aria-multiline', () => {
    editor.setUp('', EditorView.contentAttributes.of({
      'role': 'textbox',
      'aria-multiline': 'true',
    }));

    const contentDOM = window.editor.contentDOM;
    expect(contentDOM.getAttribute('aria-multiline')).toBe('true');
  });

  test('test contentDOM is contenteditable', () => {
    editor.setUp('');

    const contentDOM = window.editor.contentDOM;
    expect(contentDOM.getAttribute('contenteditable')).toBe('true');
  });
});
