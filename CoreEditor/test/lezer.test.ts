import { describe, expect, test } from '@jest/globals';
import { EditorView } from '@codemirror/view';
import { syntaxTree } from '@codemirror/language';
import * as editor from '../src/@test/editor';

describe('Lezer parser', () => {
  test('test StrongEmphasis', () => {
    editor.setUp('**Hello** World');

    const types = parseTypes(window.editor);
    expect(types).toContain('StrongEmphasis');
    expect(types).toContain('EmphasisMark');
  });

  test('test Emphasis', () => {
    editor.setUp('*Hello* World');

    const types = parseTypes(window.editor);
    expect(types).toContain('Emphasis');
    expect(types).toContain('EmphasisMark');
  });

  test('test Strikethrough', () => {
    editor.setUp('~~Hello~~ World');

    const types = parseTypes(window.editor);
    expect(types).toContain('Strikethrough');
    expect(types).toContain('StrikethroughMark');
  });

  test('test InlineCode', () => {
    editor.setUp('`Hello` World');

    const types = parseTypes(window.editor);
    expect(types).toContain('InlineCode');
    expect(types).toContain('CodeMark');
  });

  test('test FencedCode', () => {
    editor.setUp('```\nHello World\n```');

    const types = parseTypes(window.editor);
    expect(types).toContain('FencedCode');
    expect(types).toContain('CodeMark');
    expect(types).toContain('CodeText');
  });

  test('test CodeBlock', () => {
    editor.setUp('    Hello World');

    const types = parseTypes(window.editor);
    expect(types).toContain('CodeBlock');
    expect(types).toContain('CodeText');
  });

  test('test ATXHeading', () => {
    editor.setUp('## Heading');

    const types = parseTypes(window.editor);
    expect(types).toContain('ATXHeading2');
    expect(types).toContain('HeaderMark');
  });

  test('test SetextHeading1', () => {
    editor.setUp('Heading\n======');

    const types = parseTypes(window.editor);
    expect(types).toContain('SetextHeading1');
    expect(types).toContain('HeaderMark');
  });

  test('test SetextHeading2', () => {
    editor.setUp('Heading\n------');

    const types = parseTypes(window.editor);
    expect(types).toContain('SetextHeading2');
    expect(types).toContain('HeaderMark');
  });
});

function parseTypes(editor: EditorView) {
  const types: string[] = [];
  syntaxTree(editor.state).iterate({
    enter: node => {
      types.push(node.type.name);
    },
  });

  return types;
}
