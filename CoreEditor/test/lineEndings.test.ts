import { EditorState } from '@codemirror/state';
import { describe, expect, test } from '@jest/globals';
import { LineEndings } from '../src/modules/lineEndings/types';
import * as editor from '../src/@test/editor';
import * as lineEndings from '../src/modules/lineEndings';

describe('LineEndings module', () => {
  test('test line-ending normalization', () => {
    editor.setUp('Hello\nWorld');
    expect(lineEndings.getLineEndings()).toBe(LineEndings.LF);

    editor.setText('Hello\r\nWorld');
    expect(lineEndings.getLineEndings()).toBe(LineEndings.LF);

    editor.setText('Hello\rWorld');
    expect(lineEndings.getLineEndings()).toBe(LineEndings.LF);
  });

  test('test changing line endings', () => {
    editor.setUp('Hello\r\nWorld', EditorState.lineSeparator.of('\r\n'));
    expect(lineEndings.getLineEndings()).toBe(LineEndings.CRLF);

    editor.setText('Hello\nWorld');
    expect(lineEndings.getLineEndings()).toBe(LineEndings.CRLF);
  });

  test('test detecting line break', () => {
    expect(lineEndings.getLineBreak('Hello\nWorld', '\n')).toBe(undefined);
    expect(lineEndings.getLineBreak('Hello\n\r\nWorld', '\n')).toBe('\r\n');
    expect(lineEndings.getLineBreak('Hello\n\n\r\nWorld', '\n')).toBe(undefined);
    expect(lineEndings.getLineBreak('Hello\n\r\rWorld', '\n')).toBe('\r');
    expect(lineEndings.getLineBreak('', '\n')).toBe(undefined);
    expect(lineEndings.getLineBreak('', '\r')).toBe('\r');
    expect(lineEndings.getLineBreak('', '\r\n')).toBe('\r\n');
  });

  test('test normalizing line breaks', () => {
    expect(lineEndings.normalizeLineBreaks('Hello\nWorld', undefined)).toBe('Hello\nWorld');
    expect(lineEndings.normalizeLineBreaks('Hello\nWorld', '\n')).toBe('Hello\nWorld');
    expect(lineEndings.normalizeLineBreaks('Hello\n\r\nWorld', '\n')).toBe('Hello\n\nWorld');
    expect(lineEndings.normalizeLineBreaks('Hello\n\n\r\nWorld', '\n')).toBe('Hello\n\n\nWorld');
    expect(lineEndings.normalizeLineBreaks('Hello\n\r\rWorld', '\n')).toBe('Hello\n\n\nWorld');
    expect(lineEndings.normalizeLineBreaks('Hello\r\nWorld', '\n')).toBe('Hello\nWorld');
    expect(lineEndings.normalizeLineBreaks('Hello\r\nWorld', '\r')).toBe('Hello\rWorld');
    expect(lineEndings.normalizeLineBreaks('Hello\r\nWorld', '\r\n')).toBe('Hello\r\nWorld');
    expect(lineEndings.normalizeLineBreaks('Hello\r\n\r\n\n\nWorld', '\r\n')).toBe('Hello\r\n\r\n\r\n\r\nWorld');
  });
});
