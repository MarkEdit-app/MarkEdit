import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { lineNumbers, highlightActiveLineGutter } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { adjustActiveLineGutter, findLineNumberGutter } from '../src/modules/lines';
import { Config } from '../src/config';
import * as editor from './utils/editor';

describe('findLineNumberGutter', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  test('matches the active gutter for a line number', () => {
    const [, target] = buildGutters('1', '2', '3'); // e.g. multiple cursors
    expect(findLineNumberGutter(2)).toBe(target);
  });

  test('returns null when no active gutter matches', () => {
    buildGutters('1', '2');
    expect(findLineNumberGutter(5)).toBeNull();
  });

  test('returns null when there are no active gutters', () => {
    expect(findLineNumberGutter(1)).toBeNull();
  });
});

describe('adjustActiveLineGutter', () => {
  afterEach(() => {
    window.editor.destroy();
    jest.restoreAllMocks();
    document.body.innerHTML = '';
  });

  // 9 lines so CodeMirror's hidden width spacer reads "9" and can collide with line 9
  const nineLineDoc = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'].join('\n');
  const sentinelHeight = '99px';

  function setUpWithCursorOnLine9() {
    editor.setUp(nineLineDoc, [lineNumbers(), highlightActiveLineGutter()]);
    window.config = { showLineNumbers: true } as Config;
    window.editor.dispatch({ selection: EditorSelection.cursor(window.editor.state.doc.length) });
  }

  // CodeMirror sets style.height inline on every gutter element, so we stub the line rect to a
  // sentinel height and assert only the element we resize carries it.
  function adjustWithSentinelRect() {
    const rectSpy = jest.spyOn(HTMLElement.prototype, 'getBoundingClientRect')
      .mockReturnValue({ height: 99 } as DOMRect);
    try {
      adjustActiveLineGutter();
    } finally {
      rectSpy.mockRestore();
    }
  }

  // Contract guard: fails if a CodeMirror upgrade stops rendering this selector for the caret line.
  test('CodeMirror renders .cm-lineNumbers .cm-activeLineGutter for the caret line', () => {
    setUpWithCursorOnLine9();
    const active = document.querySelectorAll('.cm-lineNumbers .cm-activeLineGutter');
    expect(active.length).toBe(1);
    expect(active[0].textContent).toBe('9');
  });

  // Spacer-agnostic: never identifies the spacer, just asserts nothing but the active gutter is
  // resized. Catches any future spacer change that would let it be picked up.
  test('resizes only the active line gutter, leaving every other gutter untouched', () => {
    setUpWithCursorOnLine9();
    const allGutters = [...document.querySelectorAll('.cm-lineNumbers .cm-gutterElement')] as HTMLElement[];
    const active = document.querySelector('.cm-lineNumbers .cm-activeLineGutter') as HTMLElement;
    expect(allGutters).toContain(active); // active line is one of the gutters
    adjustWithSentinelRect();

    const resized = allGutters.filter(element => element.style.height === sentinelHeight);
    expect(resized).toEqual([active]); // exactly one resized, and it is the active line
  });
});

function buildGutters(...activeLineNumbers: string[]): HTMLElement[] {
  const container = document.createElement('div');
  container.className = 'cm-lineNumbers';

  const elements = activeLineNumbers.map(text => {
    const element = document.createElement('div');
    element.className = 'cm-gutterElement cm-activeLineGutter';
    element.textContent = text;
    container.appendChild(element);
    return element;
  });

  document.body.appendChild(container);
  return elements;
}
