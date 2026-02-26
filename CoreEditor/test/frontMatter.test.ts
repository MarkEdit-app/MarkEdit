import { describe, expect, test } from '@jest/globals';
import { frontMatterRange, removeFrontMatter } from '../src/modules/frontMatter';
import * as editor from './utils/editor';

describe('Front Matter tests', () => {
  test('test frontMatter parsing', () => {
    editor.setUp('Hello World');
    expect(frontMatterRange()).toBe(undefined);

    editor.setUp('---\ntitle: MarkEdit\n---\n\nHello World');
    expect(frontMatterRange()).toStrictEqual({ from: 0, to: 24 });

    const source = '---\ntitle: WhatCopied\n---\n\nHello World';
    expect(frontMatterRange(source)).toStrictEqual({ from: 0, to: 26 });
    expect(removeFrontMatter(source)).toBe('Hello World');
  });
});
