import { describe, expect, test } from '@jest/globals';
import { sleep } from '../src/@test/helpers';
import * as editor from '../src/@test/editor';
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
});
