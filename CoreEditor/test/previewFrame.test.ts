import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { renderPreview } from '../src/modules/preview/render';

const source = '</script><script>window.webkit.messageHandlers.bridge.postMessage({})</script>';

describe('Preview frame', () => {
  afterEach(() => {
    jest.restoreAllMocks();
    document.body.innerHTML = '';
  });

  test.each(['mermaid', 'katex', 'table'])('keeps %s source out of the frame document', type => {
    const frame = document.body.appendChild(document.createElement('iframe'));
    renderPreview(frame, type, source);

    expect(frame.srcdoc).not.toContain(source);
    expect(frame.srcdoc).toContain("default-src 'none'");
    expect(frame.srcdoc).toContain('https://cdn.jsdelivr.net');
    expect(frame.srcdoc).not.toContain('window.webkit');
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
});
