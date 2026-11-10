import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { StateEffect } from '@codemirror/state';
import { typewriterPadding } from '../src/styling/typewriter';
import * as editor from './utils/editor';

describe('Typewriter bottom padding', () => {
  afterEach(() => {
    window.editor.destroy();
    jest.restoreAllMocks();
  });

  function setUp() {
    editor.setUp('Last line');
    const view = window.editor;
    view.dispatch({ effects: StateEffect.appendConfig.of(typewriterPadding) });
    window.config.typewriterMode = true;
    view.contentDOM.style.paddingBottom = '400px';

    Object.defineProperty(view.scrollDOM, 'clientHeight', { configurable: true, value: 800 });
    jest.spyOn(view.contentDOM, 'getBoundingClientRect').mockReturnValue(new DOMRect(0, 0, 600, 1000));

    const caret = jest.spyOn(view, 'coordsAtPos').mockReturnValue({ top: 550, bottom: 570, left: 0, right: 0 });
    const measure = jest.spyOn(view, 'requestMeasure').mockImplementation(request => {
      if (request !== undefined) {
        request.write?.(request.read(view), view);
      }
    });

    return {
      view, caret, measure,
      update: () => view.plugin(typewriterPadding)?.update(),
      padding: () => view.contentDOM.style.getPropertyValue('--typewriter-bottom-padding'),
    };
  }

  test('aligns the final caret center with the scroll viewport midpoint', () => {
    const { update, padding, caret, view } = setUp();
    update();

    // The caret center is 40px above the unpadded content bottom
    expect(padding()).toBe('360px');
    expect(caret).toHaveBeenCalledWith(view.state.doc.length);
  });

  test('remeasures after changes to the last line or viewport height', () => {
    const { update, padding, caret, view } = setUp();
    update();

    caret.mockReturnValue({ top: 520, bottom: 560, left: 0, right: 0 });
    update();
    expect(padding()).toBe('340px');

    Object.defineProperty(view.scrollDOM, 'clientHeight', { value: 600 });
    update();
    expect(padding()).toBe('240px');
  });

  test('converts scaled caret geometry to CSS pixels', () => {
    const { update, padding, caret, view } = setUp();
    jest.spyOn(view, 'scaleY', 'get').mockReturnValue(2);
    jest.spyOn(view.contentDOM, 'getBoundingClientRect').mockReturnValue(new DOMRect(0, 0, 1200, 2000));
    caret.mockReturnValue({ top: 1100, bottom: 1140, left: 0, right: 0 });

    update();
    expect(padding()).toBe('360px');
  });

  test('rounds the final scroll offset down rather than the padding', () => {
    const { update, padding, caret } = setUp();
    caret.mockReturnValue({ top: 550.75, bottom: 570.75, left: 0, right: 0 });
    update();

    expect(padding()).toBe('360px');
  });

  test('includes the scroll position and viewport origin when rounding', () => {
    const { update, padding, view } = setUp();
    view.scrollDOM.scrollTop = 100.5;
    jest.spyOn(view.scrollDOM, 'getBoundingClientRect').mockReturnValue(new DOMRect(0, 20.25, 600, 800));
    update();

    expect(padding()).toBe('359.75px');
  });

  test('retains the last measurement while the final caret is not rendered', () => {
    const { update, padding, caret } = setUp();
    update();
    caret.mockReturnValue(null);

    update();
    expect(padding()).toBe('360px');
  });

  test('does not measure outside typewriter mode', () => {
    const { update, padding, measure } = setUp();
    window.config.typewriterMode = false;
    update();

    expect(measure).not.toHaveBeenCalled();
    expect(padding()).toBe('');
  });

  test('clears the variable when disabled and restores it when reenabled', () => {
    const { update, padding } = setUp();
    update();
    expect(padding()).toBe('360px');

    window.config.typewriterMode = false;
    update();
    expect(padding()).toBe('');

    window.config.typewriterMode = true;
    update();
    expect(padding()).toBe('360px');
  });

  test('does not restore the variable from a pending measurement after disabling', () => {
    const { update, padding, measure, view } = setUp();
    let pending: Parameters<typeof view.requestMeasure>[0];
    measure.mockImplementation(request => {
      pending = request;
    });

    update();
    window.config.typewriterMode = false;

    update();
    expect(pending).toBeDefined();
    pending?.write?.(360, view);
    expect(padding()).toBe('');
  });

  test('preserves script-set inline padding', () => {
    const { update, view } = setUp();
    update();
    expect(view.contentDOM.style.paddingBottom).toBe('400px');

    window.config.typewriterMode = false;
    update();
    expect(view.contentDOM.style.paddingBottom).toBe('400px');
  });

  test('avoids repeated style writes for unchanged geometry', () => {
    const { update, view } = setUp();
    const setProperty = jest.spyOn(view.contentDOM.style, 'setProperty');
    update();
    update();
    expect(setProperty).toHaveBeenCalledTimes(1);
  });

  test('does not produce negative padding in a small viewport', () => {
    const { update, padding, view } = setUp();
    Object.defineProperty(view.scrollDOM, 'clientHeight', { value: 40 });
    update();
    expect(padding()).toBe('0px');
  });
});
