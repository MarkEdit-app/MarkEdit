import { describe, expect, test } from '@jest/globals';
import { EditorView } from '@codemirror/view';
import { syntaxTree } from '@codemirror/language';
import { getNodesNamed, getReadableContent } from '../src/modules/lezer';
import * as editor from './utils/editor';

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

  test('test FrontMatter', () => {
    editor.setUp('---\ntitle: MarkEdit\n---\n\nHello World');

    const types = parseTypes(window.editor);
    expect(types).toContain('Frontmatter');
    expect(types).toContain('DashLine');
    expect(types).toContain('BlockMapping');
    expect(types).toContain('Pair');
    expect(types).toContain('Key');
    expect(types).toContain('Literal');
    expect(types).toContain(':');

    // These nodes are present without proper frontMatter parsing
    expect(types).not.toContain('HorizontalRule');
    expect(types).not.toContain('SetextHeading2');
    expect(types).not.toContain('HeaderMark');
  });

  test('test footnote', () => {
    editor.setUp('[^footnote]\n\n[^footnote]:');

    const types = parseTypes(window.editor);
    expect(types).toContain('Link');
    expect(types).toContain('LinkMark');
  });

  test('test markdown link', () => {
    editor.setUp('![image](url)\n\n[title](url)');

    const types = parseTypes(window.editor);
    expect(types).toContain('Image');
    expect(types).toContain('Link');
    expect(types).toContain('LinkMark');
    expect(types).toContain('URL');
  });

  test('test reference style link', () => {
    editor.setUp('[reference][link]\n\n[link]:');

    const types = parseTypes(window.editor);
    expect(types).toContain('Link');
    expect(types).toContain('LinkLabel');
  });

  test('test getNodesNamed', () => {
    editor.setUp('[^footnote]\n\n[reference][link]\n\n[standard](link)');

    const nodes = getNodesNamed(window.editor.state, ['Link']);
    expect(nodes.length).toBe(3);
  });

  test('test getting readable content', () => {
    expect(getReadableContent('Hello')).toStrictEqual({
      trimmedText: 'Hello',
      paragraphCount: 1,
      commentCount: 0,
    });

    expect(getReadableContent('<!-- Hello -->')).toStrictEqual({
      trimmedText: '',
      paragraphCount: 0,
      commentCount: 1,
    });

    expect(getReadableContent('<!-- Hello -->\nWorld')).toStrictEqual({
      trimmedText: 'World',
      paragraphCount: 1,
      commentCount: 1,
    });

    expect(getReadableContent('<!-- Hello -->\n<!-- World -->')).toStrictEqual({
      trimmedText: '',
      paragraphCount: 0,
      commentCount: 2,
    });

    expect(getReadableContent('<!-- Hello --> World -->')).toStrictEqual({
      trimmedText: ' World -->',
      paragraphCount: 0,
      commentCount: 1,
    });

    expect(getReadableContent('Hello <!-- Hello \n\n World -->')).toStrictEqual({
      trimmedText: 'Hello <!-- Hello \n\n World -->',
      paragraphCount: 2,
      commentCount: 0,
    });

    expect(getReadableContent('<!-- Hello \n\n World -->')).toStrictEqual({
      trimmedText: '',
      paragraphCount: 0,
      commentCount: 1,
    });

    expect(getReadableContent('Hello <!-- Hello \n.\n. World -->')).toStrictEqual({
      trimmedText: 'Hello ',
      paragraphCount: 1,
      commentCount: 1,
    });

    expect(getReadableContent('<!-- Hello -->World\n\nHello <!-- World -->')).toStrictEqual({
      trimmedText: 'World\n\nHello ',
      paragraphCount: 1,
      commentCount: 2,
    });
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
