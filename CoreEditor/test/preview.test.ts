import { afterEach, beforeEach, describe, expect, jest, test } from '@jest/globals';
import { PreviewType, showPreview } from '../src/modules/preview';
import { renderPreview } from '../src/modules/preview/render';
import { renderTable } from '../src/modules/preview/renderers/table';
import { renderMermaid } from '../src/modules/preview/renderers/mermaid';
import { Localizable } from '../src/config';
import { globalState } from '../src/common/store';
import loadModule from '../src/modules/preview/renderers/loadModule';
import * as editor from './utils/editor';

jest.mock('../src/modules/preview/renderers/loadModule', () => ({
  __esModule: true,
  default: jest.fn(),
}));

jest.mock('../src/modules/preview/render', () => ({
  renderPreview: jest.fn<() => void>(),
}));

describe('Preview overlay', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    editor.setUp('Unchanged document');

    Object.defineProperty(HTMLElement.prototype, 'animate', {
      configurable: true,
      value: jest.fn(() => ({ finished: Promise.resolve(), cancel: jest.fn() })),
    });

    Object.defineProperty(HTMLDialogElement.prototype, 'animate', {
      configurable: true,
      value: jest.fn(() => ({ finished: Promise.resolve(), cancel: jest.fn() })),
    });

    Object.defineProperty(HTMLDialogElement.prototype, 'showModal', {
      configurable: true,
      value() {
        this.open = true;
        this.querySelector('[autofocus]')?.focus();
      },
    });

    Object.defineProperty(HTMLDialogElement.prototype, 'close', {
      configurable: true,
      value() {
        this.open = false;
        this.dispatchEvent(new Event('close'));
      },
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
    globalState.colors = undefined;
    document.querySelector('dialog')?.close();
    document.querySelectorAll('.cm-md-previewButton').forEach(button => button.remove());
  });

  function open(type: string, code: string) {
    const button = document.createElement('span');
    button.className = 'cm-md-previewButton';
    button.dataset.code = code;
    button.dataset.type = type;
    button.addEventListener('click', showPreview);
    document.body.appendChild(button);
    button.click();
    return document.querySelector('dialog');
  }

  test.each(Object.values(PreviewType))('opens %s in a sandboxed frame without an anchor', type => {
    const focus = jest.spyOn(HTMLElement.prototype, 'focus');
    const dialog = open(type, 'test');
    const frame = dialog?.querySelector('iframe');

    expect(dialog?.open).toBe(true);
    expect(getComputedStyle(window.editor.dom).visibility).toBe('visible');
    expect(document.activeElement).toBe(dialog?.querySelector('button'));
    expect(focus).toHaveBeenCalledTimes(1);
    expect(dialog?.parentElement).toBe(document.body);
    expect(frame?.getAttribute('sandbox')).toBe('allow-scripts');

    const args = jest.mocked(renderPreview).mock.calls[0];
    expect(args[0]).toBe(frame);
    expect(args.slice(1)).toEqual([type, 'test']);
  });

  test.each([['Fermer', 'Fermer'], [undefined, 'Close']])('localizes the close button with %s', (title, expected) => {
    jest.replaceProperty(window, 'config', {
      ...window.config,
      localizable: title === undefined ? undefined : { closeButtonTitle: title } as Localizable,
    });

    const button = open(PreviewType.table, 'test')?.querySelector('button');
    expect(button?.title).toBe(expected);
    expect(button?.getAttribute('aria-label')).toBe(expected);
  });

  test('uses the current editor colors', () => {
    globalState.colors = {
      background: '#282a36',
      text: '#f8f8f2',
    } as NonNullable<typeof globalState.colors>;

    const dialog = open(PreviewType.table, 'test');
    expect(dialog?.style.getPropertyValue('--preview-background')).toBe('#282a36');
    expect(dialog?.style.getPropertyValue('--preview-text')).toBe('#f8f8f2');
  });

  test('updates open preview colors and stops observing after close', () => {
    const dialog = open(PreviewType.table, 'test');
    globalState.colors = {
      background: '#282a36', text: '#f8f8f2',
    } as NonNullable<typeof globalState.colors>;

    window.dispatchEvent(new Event('editor-colors-changed'));
    expect(dialog?.style.getPropertyValue('--preview-background')).toBe('#282a36');
    expect(dialog?.style.getPropertyValue('--preview-text')).toBe('#f8f8f2');

    dialog?.close();
    globalState.colors.background = '#ffffff';
    window.dispatchEvent(new Event('editor-colors-changed'));
    expect(dialog?.style.getPropertyValue('--preview-background')).toBe('#282a36');
  });

  test('closing restores focus without changing the document or selection', async () => {
    window.editor.dispatch({ selection: { anchor: 4 } });
    const dialog = open(PreviewType.table, '| Test |');
    dialog?.querySelector('button')?.click();

    await Promise.resolve();
    await Promise.resolve();

    expect(document.querySelector('dialog')).toBeNull();
    expect(getComputedStyle(window.editor.dom).visibility).toBe('visible');
    expect(window.editor.hasFocus).toBe(true);
    expect(window.editor.state.doc.toString()).toBe('Unchanged document');
    expect(window.editor.state.selection.main.anchor).toBe(4);
  });

  test('does not duplicate overlays or accept unknown preview types', () => {
    expect(open('constructor', 'test')).toBeNull();
    open(PreviewType.table, 'first');
    open(PreviewType.katex, 'second');
    expect(document.querySelectorAll('dialog')).toHaveLength(1);
  });

  test('scales the editor back and the preview forward, then cancels scales on close', () => {
    const animate = jest.spyOn(HTMLElement.prototype, 'animate');
    const dialog = open(PreviewType.table, 'test');
    expect(animate.mock.contexts).toEqual([window.editor.dom, dialog?.querySelector('.cm-previewContent')]);
    expect(animate.mock.calls).toEqual([
      [[{ scale: '1' }, { scale: '0.96' }], { duration: 200, easing: 'ease-out', fill: 'forwards' }],
      [[{ scale: '0.96' }, { scale: '1' }], { duration: 200, easing: 'ease-out', fill: 'forwards' }],
    ]);

    dialog?.close();
    animate.mock.results.forEach(result => expect((result.value as Animation).cancel).toHaveBeenCalledTimes(1));
  });

  test.each(['button', 'Escape'])('%s reveals the editor during one fade before closing', async trigger => {
    const dialog = open(PreviewType.table, 'test');
    if (!dialog) throw new Error('Missing dialog');
    let finish = () => {};
    const finished = new Promise<void>(resolve => { finish = resolve; });
    const animate = jest.spyOn(dialog, 'animate').mockReturnValue({ finished } as unknown as Animation);
    const cancel = new Event('cancel', { cancelable: true });
    if (trigger === 'button') dialog.querySelector('button')?.click();
    dialog.dispatchEvent(cancel);
    dialog.querySelector('button')?.click();

    expect(cancel.defaultPrevented).toBe(true);
    expect(dialog.open).toBe(true);
    expect(getComputedStyle(window.editor.dom).visibility).toBe('visible');
    expect(document.activeElement).toBe(dialog.querySelector('button'));
    expect(animate).toHaveBeenCalledTimes(1);
    finish();

    await Promise.resolve();
    await Promise.resolve();
    expect(document.querySelector('dialog')).toBeNull();
  });

  test('reduced motion dismisses immediately', () => {
    jest.spyOn(window, 'matchMedia').mockReturnValue({ matches: true } as MediaQueryList);
    const dialog = open(PreviewType.table, 'test');
    dialog?.querySelector('button')?.click();
    expect(dialog?.animate).not.toHaveBeenCalled();
    expect(document.querySelector('dialog')).toBeNull();
  });

  test('passes source as data without interpolating HTML', () => {
    const code = '</script><script>alert(1)</script> $& $$';
    const dialog = open(PreviewType.table, code);
    const args = jest.mocked(renderPreview).mock.calls[0];
    expect(args[0]).toBe(dialog?.querySelector('.cm-previewFrame'));
    expect(args.slice(1)).toEqual([PreviewType.table, code]);
    expect(dialog?.querySelector('script')).toBeNull();
  });

  test('does not accept frame close messages', () => {
    const dialog = open(PreviewType.table, 'test');
    window.dispatchEvent(new MessageEvent('message', { data: 'close-preview', source: window }));
    expect(dialog?.open).toBe(true);
  });
});

describe('Mermaid preview rendering', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('serializes appearance changes during rendering and switches back to light', async () => {
    const appearance = Object.assign(new EventTarget(), { matches: false });
    jest.spyOn(window, 'matchMedia').mockReturnValue(appearance as MediaQueryList);
    let finishInitial: (result: { svg: string }) => void = () => {};
    const initial = new Promise<{ svg: string }>(resolve => { finishInitial = resolve; });
    const initialize = jest.fn();
    const render = jest.fn<() => Promise<{ svg: string }>>()
      .mockReturnValueOnce(initial)
      .mockResolvedValueOnce({ svg: '<svg data-theme="dark" viewBox="0 0 936 103"></svg>' })
      .mockResolvedValueOnce({ svg: '<svg data-theme="light" viewBox="0 0 936 103"></svg>' });
    jest.mocked(loadModule).mockReset().mockResolvedValue({ default: { initialize, render } });

    const container = document.createElement('div');
    const rendering = renderMermaid(container, 'graph TD; Start --> Finish', loadModule);
    await Promise.resolve();

    appearance.matches = true;
    appearance.dispatchEvent(new Event('change'));
    expect(render).toHaveBeenCalledTimes(1);
    finishInitial({ svg: '<svg data-theme="initial"></svg>' });

    await rendering;
    await new Promise(resolve => setTimeout(resolve, 0));
    expect(initialize).toHaveBeenLastCalledWith({ theme: 'dark', startOnLoad: false });
    expect(container.querySelector('svg')?.getAttribute('data-theme')).toBe('dark');
    expect(container.querySelector('svg')?.style.width).toBe('936px');

    appearance.matches = false;
    appearance.dispatchEvent(new Event('change'));
    await new Promise(resolve => setTimeout(resolve, 0));
    expect(initialize).toHaveBeenLastCalledWith({ theme: 'default', startOnLoad: false });
    expect(container.querySelector('svg')?.getAttribute('data-theme')).toBe('light');
    expect(container.querySelector('svg')?.style.width).toBe('936px');
    expect(loadModule).toHaveBeenCalledTimes(1);
  });
});

describe('Table preview rendering', () => {
  beforeEach(() => {
    jest.mocked(loadModule).mockReset();
  });

  test('sanitizes parsed HTML before returning it', async () => {
    const source = '| Value |\n| --- |\n| **test** |';
    const html = '<table><tr><td onmouseover="alert(1)">test</td></tr></table>';
    const sanitized = '<table><tbody><tr><td>test</td></tr></tbody></table>';
    const parse = jest.fn<(code: string) => Promise<string>>().mockResolvedValue(html);
    const sanitize = jest.fn<(html: string, config: Record<string, unknown>) => string>().mockReturnValue(sanitized);
    jest.mocked(loadModule)
      .mockResolvedValueOnce({ marked: { parse } })
      .mockResolvedValueOnce({ default: { sanitize } });

    const container = document.createElement('div');
    await renderTable(container, source, loadModule);
    expect(container.innerHTML).toBe(sanitized);
    expect(parse).toHaveBeenCalledWith(source);
    expect(sanitize).toHaveBeenCalledWith(html, {
      USE_PROFILES: { html: true },
      FORBID_TAGS: ['style'],
      FORBID_ATTR: ['style'],
      SANITIZE_NAMED_PROPS: true,
    });
  });

  test('does not return unsanitized HTML when the sanitizer cannot load', async () => {
    const parse = jest.fn<() => string>().mockReturnValue('<img onerror="alert(1)">');
    jest.mocked(loadModule)
      .mockResolvedValueOnce({ marked: { parse } })
      .mockRejectedValueOnce(new Error('Sanitizer unavailable'));

    await expect(renderTable(document.createElement('div'), 'test', loadModule)).rejects.toThrow('Sanitizer unavailable');
    expect(parse).not.toHaveBeenCalled();
  });
});
