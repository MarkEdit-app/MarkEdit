import { describe, expect, test, jest, beforeEach, afterEach } from '@jest/globals';
import { startClickable, stopClickable, regexp } from '../src/styling/nodes/link';

// Mock the events module before importing link.ts so the timer callback's
// internal isMetaKeyDown() check is driven by the test.
let mockMetaKeyDown = false;
jest.mock('../src/modules/events', () => ({
  isMetaKeyDown: () => mockMetaKeyDown,
}));

const ACTIVATION_DELAY_MS = 150;

function makeLinkElement(text = 'click me'): HTMLElement {
  const el = document.createElement('span');
  el.className = 'cm-md-link';
  // The activation callback reads color from the first child node, so include one.
  const inner = document.createElement('span');
  inner.textContent = text;
  el.appendChild(inner);
  document.body.appendChild(el);
  return el;
}

describe('startClickable / stopClickable', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    mockMetaKeyDown = false;
    window.config = {} as typeof window.config;
  });

  afterEach(() => {
    jest.useRealTimers();
    document.body.innerHTML = '';
    // Reset the module-level focusedElement by stopping any pending state.
    stopClickable();
  });

  test('does not apply styles synchronously (delay)', () => {
    const el = makeLinkElement();
    mockMetaKeyDown = true;

    startClickable(el, true);
    expect(el.style.cursor).toBe('');
    expect(el.style.textDecoration).toBe('');
  });

  test('applies styles after the activation delay', () => {
    const el = makeLinkElement();
    mockMetaKeyDown = true;

    startClickable(el, true);
    jest.advanceTimersByTime(ACTIVATION_DELAY_MS);

    expect(el.style.cursor).toBe('pointer');
    expect(el.style.textDecoration).toContain('underline');
  });

  test('stopClickable cancels a pending activation (no flash)', () => {
    const el = makeLinkElement();
    mockMetaKeyDown = true;

    startClickable(el, true);
    // Cmd released before the timer fires.
    mockMetaKeyDown = false;
    stopClickable(el);
    jest.advanceTimersByTime(ACTIVATION_DELAY_MS);

    expect(el.style.cursor).toBe('');
    expect(el.style.textDecoration).toBe('');
  });

  test('activation callback bails if meta key is released during the delay', () => {
    const el = makeLinkElement();
    mockMetaKeyDown = true;

    startClickable(el, true);
    // Just release meta (without calling stopClickable, simulating the
    // in-callback safety check independently).
    mockMetaKeyDown = false;
    jest.advanceTimersByTime(ACTIVATION_DELAY_MS);

    expect(el.style.cursor).toBe('');
  });

  test('switching focus to a different element only activates the new one', () => {
    const a = makeLinkElement('a');
    const b = makeLinkElement('b');
    mockMetaKeyDown = true;

    startClickable(a, true);
    // Hover moves to b before a's timer fires.
    startClickable(b, true);
    jest.advanceTimersByTime(ACTIVATION_DELAY_MS);

    expect(a.style.cursor).toBe('');
    expect(b.style.cursor).toBe('pointer');
  });

  test('stopClickable clears applied styles and restores title', () => {
    const el = makeLinkElement();
    mockMetaKeyDown = true;

    startClickable(el, true);
    jest.advanceTimersByTime(ACTIVATION_DELAY_MS);
    expect(el.style.cursor).toBe('pointer');

    stopClickable(el);

    expect(el.style.cursor).toBe('');
    expect(el.style.textDecoration).toBe('');
    expect(el.style.textDecorationColor).toBe('');
  });

  test('startClickable with metaKeyPressed=false is a no-op', () => {
    const el = makeLinkElement();

    startClickable(el, false);
    jest.advanceTimersByTime(ACTIVATION_DELAY_MS);

    expect(el.style.cursor).toBe('');
  });
});

// Helpers for the regex tests below.
//
// In `regexp.standard`, the alternative for a markdown link `[text](url)`
// populates match[4] with "[text](" and match[5] with the URL. A bare URL
// hits the first alternative (no match[4] / match[6]). An HTML attribute
// match populates match[6] (the prefix incl. the opening quote) and match[7]
// (the URL).
function execAll(re: RegExp, input: string): RegExpExecArray[] {
  const pattern = new RegExp(re.source, re.flags);
  const matches: RegExpExecArray[] = [];

  let m: RegExpExecArray | null;
  while ((m = pattern.exec(input)) !== null) {
    matches.push(m);
    if (m[0].length === 0) {
      pattern.lastIndex++;
    }
  }

  return matches;
}

// TS types `RegExpExecArray[n]` as `string`, but unmatched alternatives
// actually return `undefined` at runtime. Cast through `unknown` to compare.
const group = (m: RegExpExecArray, i: number) => (m as unknown as (string | undefined)[])[i];
const findMarkdownLink = (input: string) => execAll(regexp.standard, input).find(m => group(m, 4) !== undefined);
const findBareUrl = (input: string) => execAll(regexp.standard, input).find(m => group(m, 4) === undefined && group(m, 6) === undefined);
const findHtmlAttrUrl = (input: string) => execAll(regexp.standard, input).find(m => group(m, 6) !== undefined);

describe('regexp.standard — markdown links', () => {
  test('matches a basic [text](url) link', () => {
    const m = findMarkdownLink('see [a](https://example.com) here');
    expect(m).toBeDefined();
    expect(m?.[5]).toBe('https://example.com');
  });

  test('captures URLs containing balanced parens (Wikipedia-style)', () => {
    const m = findMarkdownLink('[wiki](https://en.wikipedia.org/wiki/Foo_(bar))');
    expect(m).toBeDefined();
    expect(m?.[5]).toBe('https://en.wikipedia.org/wiki/Foo_(bar)');
  });

  test('strips title from [text](url "title")', () => {
    const m = findMarkdownLink('[t](https://example.com "Title")');
    expect(m).toBeDefined();
    expect(m?.[5]).toBe('https://example.com');
  });

  test('strips title with single quotes', () => {
    const m = findMarkdownLink("[t](https://example.com 'Title')");
    expect(m).toBeDefined();
    expect(m?.[5]).toBe('https://example.com');
  });

  test('handles escaped brackets in link text', () => {
    const m = findMarkdownLink('[a \\[b\\] c](https://example.com)');
    expect(m).toBeDefined();
    expect(m?.[5]).toBe('https://example.com');
  });

  test('does not match an empty destination [text]()', () => {
    expect(findMarkdownLink('[text]()')).toBeUndefined();
  });

  test('does not match [text]( "title") (empty destination + title)', () => {
    expect(findMarkdownLink('[text]( "title")')).toBeUndefined();
  });

  test('matches relative paths', () => {
    const m = findMarkdownLink('[doc](../README.md)');
    expect(m).toBeDefined();
    expect(m?.[5]).toBe('../README.md');
  });

  test('matches anchor-only destinations', () => {
    const m = findMarkdownLink('[top](#heading)');
    expect(m).toBeDefined();
    expect(m?.[5]).toBe('#heading');
  });
});

describe('regexp.standard — bare URLs', () => {
  test('matches https URL in prose', () => {
    const m = findBareUrl('Visit https://markedit.app for info.');
    expect(m).toBeDefined();
    expect(m?.[0]).toBe('https://markedit.app');
  });

  test('matches URL with query string', () => {
    const m = findBareUrl('See https://example.com/path?x=1.');
    expect(m).toBeDefined();
    expect(m?.[0].startsWith('https://example.com/path?x=1')).toBe(true);
  });
});

describe('regexp.standard — HTML attribute URLs', () => {
  test('matches href in inline HTML', () => {
    const m = findHtmlAttrUrl('<a href="https://example.com">x</a>');
    expect(m).toBeDefined();
    expect(m?.[7]).toBe('https://example.com');
  });

  test('matches src attributes', () => {
    const m = findHtmlAttrUrl('<img src="/img.png" />');
    expect(m).toBeDefined();
    expect(m?.[7]).toBe('/img.png');
  });
});

describe('regexp.footnote', () => {
  test('matches [^label]', () => {
    expect(regexp.footnote.test('[^note]')).toBe(true);
    expect(regexp.footnote.test('[^1]')).toBe(true);
  });

  test('rejects non-footnotes', () => {
    expect(regexp.footnote.test('[note]')).toBe(false);
    expect(regexp.footnote.test('[^]')).toBe(false);
  });
});

describe('regexp.reference', () => {
  test('matches [text][label] and captures the label', () => {
    const r = '[text][label]'.match(regexp.reference);
    expect(r).not.toBeNull();
    expect(r?.[1]).toBe('label');
  });

  test('allows multiple whitespace between text and label', () => {
    const r = '[text]   [label]'.match(regexp.reference);
    expect(r).not.toBeNull();
    expect(r?.[1]).toBe('label');
  });

  test('handles escaped brackets in text and label', () => {
    const r = '[a\\]b][c\\]d]'.match(regexp.reference);
    expect(r).not.toBeNull();
    expect(r?.[1]).toBe('c\\]d');
  });

  test('rejects single-bracket strings', () => {
    expect('[just-text]'.match(regexp.reference)).toBeNull();
  });
});
