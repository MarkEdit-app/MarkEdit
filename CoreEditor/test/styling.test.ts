import { afterEach, beforeEach, describe, expect, jest, test } from '@jest/globals';
import { Compartment } from '@codemirror/state';
import { gutterExtensions } from '../src/styling/nodes/gutter';
import { renderWhitespaceBeforeCaret } from '../src/styling/nodes/invisible';
import { selectedLinesDecoration } from '../src/styling/nodes/selection';
import { adjustAlpha } from '../src/styling/helper';
import { setFontFace, setFontSize, setLineHeight, setTheme } from '../src/styling/config';
import { InvisiblesBehavior } from '../src/config';
import { editingState, styleSheets } from '../src/common/store';
import { classHighlighters } from '../src/styling/markdown';
import GitHubLight from '../src/styling/themes/github-light';
import { loadTheme } from '../src/styling/themes';
import { sleep } from './utils/helpers';
import * as editor from './utils/editor';

describe('Styling module', () => {
  test('test CodeMirror class names', async () => {
    editor.setUp('Hello World', [
      ...gutterExtensions,
    ]);

    await sleep(200);
    const elements = [...document.querySelectorAll('*')] as HTMLElement[];

    const classNames = elements.reduce((acc, cur) => {
      [...cur.classList].forEach(cls => acc.add(cls.toString()));
      return acc;
    }, new Set());

    expect(classNames.has('cm-editor')).toBeTruthy();
    expect(classNames.has('cm-focused')).toBeTruthy();
    expect(classNames.has('cm-content')).toBeTruthy();
    expect(classNames.has('cm-scroller')).toBeTruthy();
    expect(classNames.has('cm-gutters')).toBeTruthy();
    expect(classNames.has('cm-gutter')).toBeTruthy();
    expect(classNames.has('cm-gutterElement')).toBeTruthy();
    expect(classNames.has('cm-foldGutter')).toBeTruthy();
    expect(classNames.has('cm-line')).toBeTruthy();
    expect(classNames.has('cm-lineNumbers')).toBeTruthy();
  });

  test('styles GFM table delimiters separately from content', () => {
    editor.setUp('| Name | Value |\n|:-----|------:|\n| one | two |', [
      classHighlighters,
      GitHubLight().extension,
    ]);

    const marks = [...window.editor.dom.querySelectorAll('.cm-md-tableMark')];
    expect(marks.map(mark => mark.textContent)).toEqual(['|', '|', '|', '|:-----|------:|', '|', '|', '|']);
    expect(getComputedStyle(marks[0]).fontWeight).toBe('500');
  });

  test('decorate active line immediately for focus mode', async () => {
    editor.setUp('line 1\nline 2', selectedLinesDecoration);
    await sleep(200);

    const selected = document.querySelectorAll('.cm-selectedLineRange');
    expect(selected.length).toBe(1);
  });
});

describe('Typography configuration', () => {
  let rootStyle: string;
  beforeEach(() => {
    rootStyle = document.documentElement.style.cssText;
    window.config = {} as typeof window.config;
  });

  afterEach(() => {
    document.documentElement.style.cssText = rootStyle;
    styleSheets.fontFace?.remove();
    styleSheets.fontSize?.remove();
    styleSheets.lineHeight?.remove();

    delete styleSheets.fontFace;
    delete styleSheets.fontSize;
    delete styleSheets.lineHeight;
    window.config.headerFontSizeDiffs = undefined;
  });

  test('updates the font-family variable with ordered fallbacks without rewriting rules', () => {
    setFontFace({ family: 'Courier New' });
    const sheet = styleSheets.fontFace;
    if (sheet === undefined || sheet.sheet === null) {
      throw new Error('Font-face stylesheet was not created');
    }

    const rule = sheet.sheet.cssRules[0];
    if (!(rule instanceof CSSStyleRule)) {
      throw new Error('Font-face stylesheet is missing its rule');
    }

    const initialRule = rule.cssText;
    expect(rule.style.getPropertyValue('font-family')).toBe('var(--markedit-editor-font-family)');
    expect(document.documentElement.style.getPropertyValue('--markedit-editor-font-family')).toBe(
      'Courier New, ui-monospace, monospace, Menlo, system-ui, Helvetica, Arial, sans-serif',
    );

    setFontFace({ family: 'system-ui' });
    expect(document.documentElement.style.getPropertyValue('--markedit-editor-font-family')).toBe(
      'system-ui, ui-monospace, monospace, Menlo, Helvetica, Arial, sans-serif',
    );

    expect(styleSheets.fontFace).toBe(sheet);
    expect(rule.cssText).toBe(initialRule);
  });

  test('removes optional font weight and style when returning to a family-only preference', () => {
    setFontFace({ family: 'Menlo', weight: '600', style: 'italic' });
    const rule = styleSheets.fontFace?.sheet?.cssRules[0];
    if (!(rule instanceof CSSStyleRule)) {
      throw new Error('Font-face stylesheet is missing its rule');
    }

    expect(rule.style.fontWeight).toBe('600');
    expect(rule.style.fontStyle).toBe('italic');

    setFontFace({ family: 'Arial' });
    expect(rule.style.fontWeight).toBe('');
    expect(rule.style.fontStyle).toBe('');
    expect(rule.style.getPropertyValue('font-family')).toBe('var(--markedit-editor-font-family)');
  });

  test('updates font sizes without rewriting rules when heading preferences change', () => {
    setFontSize(15);
    const sheet = styleSheets.fontSize;
    if (sheet === undefined || sheet.sheet === null) {
      throw new Error('Font-size stylesheet was not created');
    }

    const rules = Array.from(sheet.sheet.cssRules, rule => rule.cssText);
    const sizes = () => [
      '--markedit-editor-font-size',
      '--markedit-fold-placeholder-font-size',
      ...[1, 2, 3, 4, 5, 6].map(level => `--markedit-markdown-heading${level}-font-size`),
    ].map(name => document.documentElement.style.getPropertyValue(name));

    expect(sizes()).toEqual(
      ['15px', '11px', '20px', '18px', '16px', '15px', '15px', '15px'],
    );

    window.config.headerFontSizeDiffs = [8, 0, -1];
    setFontSize(20);
    expect(sizes()).toEqual(['20px', '16px', '28px', '20px', '19px', '20px', '20px', '20px']);

    window.config.headerFontSizeDiffs = [];
    setFontSize(17.5);
    expect(sizes()).toEqual(['17.5px', '13.5px', '17.5px', '17.5px', '17.5px', '17.5px', '17.5px', '17.5px']);
    expect(styleSheets.fontSize).toBe(sheet);
    expect(Array.from(sheet.sheet.cssRules, rule => rule.cssText)).toEqual(rules);
  });

  test('updates unitless line height without replacing or rewriting its stylesheet', () => {
    setLineHeight(1.5);
    const sheet = styleSheets.lineHeight;
    if (sheet === undefined || sheet.sheet === null) {
      throw new Error('Line-height stylesheet was not created');
    }

    const rules = Array.from(sheet.sheet.cssRules, rule => rule.cssText);
    expect(document.documentElement.style.getPropertyValue('--markedit-editor-line-height')).toBe('1.5');

    setLineHeight(1.75);
    expect(document.documentElement.style.getPropertyValue('--markedit-editor-line-height')).toBe('1.75');
    expect(styleSheets.lineHeight).toBe(sheet);
    expect(Array.from(sheet.sheet.cssRules, rule => rule.cssText)).toEqual(rules);
  });
});

describe('Heading theme variables', () => {
  let rootStyle: string;
  beforeEach(() => {
    rootStyle = document.documentElement.style.cssText;
    const theme = new Compartment;
    editor.setUp('# Heading\n\n> # Quoted', [classHighlighters, theme.of(GitHubLight().extension)]);
    window.dynamics = { theme };
  });

  afterEach(() => {
    jest.restoreAllMocks();
    window.editor.destroy();
    window.editor.dom.remove();
    styleSheets.accentColor?.remove();
    delete styleSheets.accentColor;
    document.documentElement.style.cssText = rootStyle;
  });

  function headingRule() {
    const rule = styleSheets.accentColor?.sheet?.cssRules[0];
    if (!(rule instanceof CSSStyleRule)) {
      throw new Error('Heading stylesheet is missing its rule');
    }

    return rule;
  }

  test('updates heading color and clears glow without rewriting intact declarations', () => {
    setTheme(GitHubLight());
    const rule = headingRule();
    const update = jest.spyOn(rule.style, 'setProperty');
    const root = document.documentElement.style;

    setTheme(loadTheme('synthwave84'));
    expect(root.getPropertyValue('--markedit-markdown-heading-color')).toBe('#f92aad');
    expect(root.getPropertyValue('--markedit-markdown-heading-text-shadow')).toBe(
      '0 0 2px #100c0f, 0 0 5px #dc078e33, 0 0 10px #fff3',
    );

    setTheme(GitHubLight());
    expect(root.getPropertyValue('--markedit-markdown-heading-color')).toBe('#0550ae');
    expect(root.getPropertyValue('--markedit-markdown-heading-text-shadow')).toBe('none');
    expect(update).not.toHaveBeenCalled();
  });

  test('rebinds declarations altered by legacy themes on the next theme update', () => {
    setTheme(GitHubLight());
    const rule = headingRule();
    rule.style.removeProperty('color');
    rule.style.setProperty('text-shadow', 'none', 'important');

    setTheme(loadTheme('synthwave84'));
    expect(headingRule()).toBe(rule);
    expect(rule.style.getPropertyValue('color')).toBe('var(--markedit-markdown-heading-color)');
    expect(rule.style.getPropertyValue('text-shadow')).toBe('var(--markedit-markdown-heading-text-shadow)');
    expect(rule.style.getPropertyPriority('text-shadow')).toBe('');
    expect(document.documentElement.style.getPropertyValue('--markedit-markdown-heading-color')).toBe('#f92aad');
  });
});

describe('adjustAlpha', () => {
  test('adds alpha to opaque hex colors', () => {
    expect(adjustAlpha('#ffffff', 0.4)).toBe('#ffffff66');
    expect(adjustAlpha('#fff', 0.4)).toBe('#ffffff66');
  });

  test('multiplies existing alpha', () => {
    expect(adjustAlpha('#ffffffd9', 0.4)).toBe('#ffffff57');
    expect(adjustAlpha('#fff8', 0.5)).toBe('#ffffff44');
  });

  test('mixes non-hex CSS colors with transparency', () => {
    expect(adjustAlpha('rgb(255, 255, 255)', 0.4)).toBe('color-mix(in srgb, rgb(255, 255, 255) 40%, transparent)');
    expect(adjustAlpha('var(--text-color)', 0.5)).toBe('color-mix(in srgb, var(--text-color) 50%, transparent)');
  });
});

describe('renderWhitespaceBeforeCaret', () => {
  afterEach(() => {
    editingState.compositionEnded = true;
  });

  async function render() {
    editor.setUp('Hello');
    window.config.invisiblesBehavior = InvisiblesBehavior.always;

    const dispatch = jest.spyOn(window.editor, 'dispatch');
    renderWhitespaceBeforeCaret();
    await sleep(100);

    return dispatch;
  }

  test('refreshes the focus when no composition is active', async () => {
    expect(await render()).toHaveBeenCalled();
  });

  // Space is the conversion key for input methods like Japanese
  test('does not refresh the focus during a composition', async () => {
    editingState.compositionEnded = false;
    expect(await render()).not.toHaveBeenCalled();
  });
});
