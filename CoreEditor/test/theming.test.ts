import { EditorView } from '@codemirror/view';
import { HighlightStyle, syntaxHighlighting } from '@codemirror/language';
import { tags } from '@lezer/highlight';
import { describe, expect, test } from '@jest/globals';

import { initThemeExtractors } from '../src/api/modules';

describe('Test theming internals', () => {
  initThemeExtractors();

  test('test __extractStyleRules', () => {
    const sample = window.__flattenThemeExtensions__(EditorView.theme({ '&': { color: 'cyan' } }));
    expect(sample.some(o => typeof window.__extractStyleRules__(o) === 'object')).toBeTruthy();
  });

  test('test __extractHighlightSpecs', () => {
    const sample = window.__flattenThemeExtensions__(syntaxHighlighting(HighlightStyle.define([{ tag: tags.heading, color: 'cyan' }])));
    expect(sample.some(o => typeof window.__extractHighlightSpecs__(o) === 'object')).toBeTruthy();
  });
});
