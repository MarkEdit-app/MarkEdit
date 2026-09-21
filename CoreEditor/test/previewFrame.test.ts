import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { runInNewContext } from 'node:vm';
import { renderPreview } from '../src/modules/preview/render';
import { renderInFrame } from '../src/modules/preview/frame';
import { globalState } from '../src/common/store';

const source = '</script><script>window.webkit.messageHandlers.bridge.postMessage({})</script>';

describe('Preview frame', () => {
  afterEach(() => {
    document.querySelectorAll('iframe').forEach(frame => frame.dispatchEvent(new Event('preview-close')));
    jest.restoreAllMocks();
    globalState.colors = undefined;
    document.body.innerHTML = '';
  });

  test.each(['mermaid', 'katex', 'table'])('keeps %s source out of the frame document', type => {
    const frame = document.body.appendChild(document.createElement('iframe'));
    renderPreview(frame, type, source);

    expect(frame.srcdoc).not.toContain(source);
    expect(frame.srcdoc).toContain("default-src 'none'");
    expect(frame.srcdoc).toContain('https://cdn.jsdelivr.net');
    expect(frame.srcdoc).toContain('img-src https: data:');
    expect(frame.srcdoc).not.toContain('window.webkit');
  });

  test('uses the current editor colors', () => {
    globalState.colors = {
      background: '#282a36',
      text: '#f8f8f2',
    } as NonNullable<typeof globalState.colors>;

    const frame = document.body.appendChild(document.createElement('iframe'));
    renderPreview(frame, 'table', source);

    const frameDocument = new DOMParser().parseFromString(frame.srcdoc, 'text/html');
    expect(frameDocument.documentElement.style.getPropertyValue('--preview-background')).toBe('#282a36');
    expect(frameDocument.documentElement.style.getPropertyValue('--preview-text')).toBe('#f8f8f2');
  });

  test.each([0, 100, -10])('updates the scroll fade from an initial offset of %s', scrollY => {
    const frame = document.body.appendChild(document.createElement('iframe'));
    renderInFrame(frame, async () => {}, '');

    const frameDocument = new DOMParser().parseFromString(frame.srcdoc, 'text/html');
    const script = frameDocument.querySelector('script')?.textContent;
    if (script === undefined) throw new Error('Missing frame script');
    const frameWindow = Object.assign(new EventTarget(), { document: frameDocument, scrollY });
    runInNewContext(script, { globalThis: frameWindow });
    expect(frameDocument.documentElement.classList.contains('preview-scrolled')).toBe(scrollY > 0);

    for (const offset of [1, 200, 0, -10]) {
      frameWindow.scrollY = offset;
      frameWindow.dispatchEvent(new Event('scroll'));
      expect(frameDocument.documentElement.classList.contains('preview-scrolled')).toBe(offset > 0);
    }
  });

  test('sends source after load and accepts completion only from its frame', () => {
    const frame = document.body.appendChild(document.createElement('iframe'));
    const postMessage = jest.spyOn(frame.contentWindow as Window, 'postMessage');
    renderPreview(frame, 'table', source);

    frame.dispatchEvent(new Event('load'));
    expect(postMessage.mock.calls[0]).toEqual([{ type: 'render-preview', code: source }, '*']);
    expect(frame.getAttribute('aria-busy')).toBe('true');

    window.dispatchEvent(new MessageEvent('message', {
      data: { type: 'preview-rendered' },
      source: window,
    }));

    expect(frame.getAttribute('aria-busy')).toBe('true');

    window.dispatchEvent(new MessageEvent('message', {
      data: { type: 'preview-rendered' },
      source: frame.contentWindow,
    }));

    expect(frame.hasAttribute('aria-busy')).toBe(false);
  });

  test('sends current colors after load and theme changes until close', () => {
    const frame = document.body.appendChild(document.createElement('iframe'));
    const postMessage = jest.spyOn(frame.contentWindow as Window, 'postMessage');
    renderPreview(frame, 'table', source);

    const originalDocument = frame.srcdoc;
    globalState.colors = {
      background: '#282a36', text: '#f8f8f2',
    } as NonNullable<typeof globalState.colors>;

    frame.dispatchEvent(new Event('load'));
    expect(postMessage.mock.calls.at(-1)).toEqual([{
      type: 'preview-colors', background: '#282a36', text: '#f8f8f2',
    }, '*']);

    globalState.colors = {
      background: '#ffffff', text: '#1f2328',
    } as NonNullable<typeof globalState.colors>;

    window.dispatchEvent(new Event('editor-colors-changed'));
    expect(postMessage.mock.calls.at(-1)).toEqual([{
      type: 'preview-colors', background: '#ffffff', text: '#1f2328',
    }, '*']);
    expect(frame.srcdoc).toBe(originalDocument);

    frame.dispatchEvent(new Event('preview-close'));
    postMessage.mockClear();
    window.dispatchEvent(new Event('editor-colors-changed'));
    expect(postMessage).not.toHaveBeenCalled();
  });
});
