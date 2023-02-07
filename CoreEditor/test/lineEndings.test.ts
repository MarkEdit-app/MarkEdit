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
});
