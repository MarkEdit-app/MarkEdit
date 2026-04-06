import { describe, expect, test } from '@jest/globals';
import { updateTextChecker } from '../src/modules/textChecker';

function createContentDOM(): HTMLElement {
  const div = document.createElement('div');
  div.setAttribute('autocomplete', 'on');
  div.setAttribute('autocapitalize', 'on');
  return div;
}

describe('TextChecker test suite', () => {
  test('test spellcheck and autocorrect enabled', () => {
    const dom = createContentDOM();
    updateTextChecker(dom, { spellcheck: true, autocorrect: true });

    expect(dom.getAttribute('spellcheck')).toBe('true');
    expect(dom.getAttribute('autocorrect')).toBe('on');
    expect(dom.hasAttribute('autocomplete')).toBe(false);
    expect(dom.hasAttribute('autocapitalize')).toBe(false);
  });

  test('test spellcheck and autocorrect disabled', () => {
    const dom = createContentDOM();
    updateTextChecker(dom, { spellcheck: false, autocorrect: false });

    expect(dom.getAttribute('spellcheck')).toBe('false');
    expect(dom.getAttribute('autocorrect')).toBe('off');
    expect(dom.hasAttribute('autocomplete')).toBe(false);
    expect(dom.hasAttribute('autocapitalize')).toBe(false);
  });

  test('test mixed options', () => {
    const dom = createContentDOM();
    updateTextChecker(dom, { spellcheck: true, autocorrect: false });

    expect(dom.getAttribute('spellcheck')).toBe('true');
    expect(dom.getAttribute('autocorrect')).toBe('off');
  });

  test('test autocomplete and autocapitalize are removed', () => {
    const dom = createContentDOM();
    expect(dom.hasAttribute('autocomplete')).toBe(true);
    expect(dom.hasAttribute('autocapitalize')).toBe(true);

    updateTextChecker(dom, { spellcheck: false, autocorrect: false });

    expect(dom.hasAttribute('autocomplete')).toBe(false);
    expect(dom.hasAttribute('autocapitalize')).toBe(false);
  });
});
