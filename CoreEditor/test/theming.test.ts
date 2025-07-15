import { EditorView } from '@codemirror/view';
import { Extension } from '@codemirror/state';
import { HighlightStyle, syntaxHighlighting } from '@codemirror/language';
import { tags } from '@lezer/highlight';
import { describe, expect, test } from '@jest/globals';

import { Config } from '../src/config';
import { initThemeExtractors } from '../src/api/modules';

describe('Test theming internals', () => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (window as any).MarkEdit = {};
  initThemeExtractors();

  test('test __extractStyleRules', () => {
    const sample = flattenThemes(EditorView.theme({ '&': { color: 'cyan' } }));
    expect(sample.some(o => typeof window.__extractStyleRules__(o) === 'object')).toBeTruthy();
  });

  test('test __extractHighlightSpecs', () => {
    const sample = flattenThemes(syntaxHighlighting(HighlightStyle.define([{ tag: tags.heading, color: 'cyan' }])));
    expect(sample.some(o => typeof window.__extractHighlightSpecs__(o) === 'object')).toBeTruthy();
  });

  test('test Config.theme property name', () => {
    type HasKey<T, K extends PropertyKey> = K extends keyof T ? true : false;
    const hasTheme: HasKey<Config, 'theme'> extends true ? true : false = true;
    expect(hasTheme).toBeTruthy();
  });
});

function flattenThemes(node: Extension): Extension[] {
  if (Array.isArray(node)) {
    return node.flatMap(flattenThemes);
  } else if ('extension' in node) {
    return flattenThemes(node.extension);
  } else {
    return [node];
  }
}
