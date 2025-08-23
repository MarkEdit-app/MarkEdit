import { describe, expect, test } from '@jest/globals';
import { sleep } from './utils/helpers';
import * as editor from './utils/editor';
import * as toc from '../src/modules/toc';

describe('Table of contents module', () => {
  test('test getting table of contents', async() => {
    editor.setUp('## Hello\n\n- One\n- Two\n- Three\n\n### MarkEdit\n\nHave fun.');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results[0].level).toBe(2);
    expect(results[0].title).toBe('Hello');
    expect(results[1].level).toBe(3);
    expect(results[1].title).toBe('  MarkEdit');
  });

  test('test Setext heading level 1 (===)', async() => {
    editor.setUp('This is title\n=============');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(1);
    expect(results[0].level).toBe(1);
    expect(results[0].title).toBe('This is title');
  });

  test('test Setext heading level 2 (---)', async() => {
    editor.setUp('This is title\n-------------');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(1);
    expect(results[0].level).toBe(2);
    expect(results[0].title).toBe('This is title');
  });

  test('test mixed ATX and Setext headings', async() => {
    editor.setUp('# ATX Level 1\n\nSetext Level 1\n==============\n\n## ATX Level 2\n\nSetext Level 2\n--------------');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(4);
    expect(results[0].level).toBe(1);
    expect(results[0].title).toBe('ATX Level 1');
    expect(results[1].level).toBe(1);
    expect(results[1].title).toBe('Setext Level 1');
    expect(results[2].level).toBe(2);
    expect(results[2].title).toBe('  ATX Level 2');
    expect(results[3].level).toBe(2);
    expect(results[3].title).toBe('  Setext Level 2');
  });

  test('test filename suggestion with Setext level 2 as first heading', async() => {
    editor.setUp('This is a title\n---------------\n\nSome content here.');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(1);
    expect(results[0].level).toBe(2);
    expect(results[0].title).toBe('This is a title');
    // This should be usable for filename suggestion even though it's level 2
  });

  test('test filename suggestion with Setext level 1 as first heading', async() => {
    editor.setUp('This is a title\n===============\n\nSome content here.');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(1);
    expect(results[0].level).toBe(1);
    expect(results[0].title).toBe('This is a title');
    // This should be usable for filename suggestion
  });
});
