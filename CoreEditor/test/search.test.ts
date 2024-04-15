import { describe, expect, test } from '@jest/globals';
import { SearchQuery } from '@codemirror/search';
import { cursorFromQuery } from '../src/modules/search/queryCursor';

import matchFromQuery from '../src/modules/search/matchFromQuery';
import rangesFromQuery from '../src/modules/search/rangesFromQuery';
import searchOccurrences from '../src/modules/search/searchOccurrences';

import * as editor from '../src/@test/editor';
import * as search from '../src/modules/search';

describe('Search module', () => {
  test('test cursorFromQuery', () => {
    editor.setUp('Hello Hello');
    search.setState(true);

    const cursor = cursorFromQuery(new SearchQuery({
      search: 'Hello',
      caseSensitive: false,
      literal: false,
      regexp: false,
      wholeWord: false,
    }));

    expect(typeof cursor?.matchAll).toBe('function');
    expect(typeof cursor?.getReplacement).toBe('function');
    expect(typeof cursor?.prevMatch).toBe('function');
    expect(typeof cursor?.nextMatch).toBe('function');
  });

  test('matchFromQuery', () => {
    editor.setUp('**Hello** Hello');
    search.setState(true);

    const query = new SearchQuery({
      search: 'Hello',
      caseSensitive: false,
      literal: false,
      regexp: false,
      wholeWord: false,
    });

    const match = matchFromQuery(query);
    expect(match?.from).toBe(2);
    expect(match?.to).toBe(7);
  });

  test('test rangesFromQuery', () => {
    editor.setUp('Hello Hello');
    search.setState(true);

    const query = new SearchQuery({
      search: 'Hello',
      caseSensitive: false,
      literal: false,
      regexp: false,
      wholeWord: false,
    });

    expect(rangesFromQuery(query).length).toBe(2);
  });

  test('test searchOccurrences', () => {
    expect(searchOccurrences('Hello, Hello, hello', 'Hello').length).toBe(2);
    expect(searchOccurrences('Hello, Hello, hello', 'hello').length).toBe(1);
  });
});
