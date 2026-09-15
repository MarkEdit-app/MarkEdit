import type { ModuleLoader } from '../renderers/loadModule';
import { globalState } from '../../../common/store';
import scriptTemplate from './script.js?raw';
import styleTemplate from './style.css?raw';

export type Renderer = (container: HTMLElement, code: string, loadModule: ModuleLoader) => Promise<void>;

export function renderInFrame(frame: HTMLIFrameElement, renderer: Renderer, code: string): void {
  const rendered = (event: MessageEvent) => {
    if (event.source !== frame.contentWindow || event.data?.type !== 'preview-rendered') {
      return;
    }

    frame.removeAttribute('aria-busy');
    window.removeEventListener('message', rendered);
  };

  window.addEventListener('message', rendered);
  frame.addEventListener('preview-close', () => {
    window.removeEventListener('message', rendered);
  }, { once: true });

  frame.addEventListener('load', () => {
    frame.contentWindow?.postMessage({ type: 'render-preview', code }, '*');
  }, { once: true });

  frame.setAttribute('aria-busy', 'true');
  frame.srcdoc = createFrameDocument(renderer);
}

function createFrameDocument(renderer: Renderer): string {
  const frameDocument = document.implementation.createHTMLDocument('');
  frameDocument.documentElement.lang = 'en';

  if (globalState.colors !== undefined) {
    frameDocument.documentElement.style.setProperty('--preview-background', globalState.colors.background);
    frameDocument.documentElement.style.setProperty('--preview-text', globalState.colors.text);
  }

  const charset = frameDocument.createElement('meta');
  charset.setAttribute('charset', 'UTF-8');

  const viewport = frameDocument.createElement('meta');
  viewport.name = 'viewport';
  viewport.content = 'width=device-width, initial-scale=1.0';

  const policy = frameDocument.createElement('meta');
  policy.httpEquiv = 'Content-Security-Policy';
  policy.content = "default-src 'none'; script-src 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'unsafe-inline' https://cdn.jsdelivr.net; font-src https://cdn.jsdelivr.net; img-src https: data:";

  const style = frameDocument.createElement('style');
  style.textContent = styleTemplate;

  const container = frameDocument.createElement('div');
  container.id = 'container';

  const script = frameDocument.createElement('script');
  script.type = 'module';
  script.textContent = scriptTemplate.replace(
    'globalThis.__MARKEDIT_RENDERER__',
    `(${renderer.toString()})`,
  );

  frameDocument.head.append(charset, viewport, policy, style);
  frameDocument.body.append(container, script);
  return `<!DOCTYPE html>\n${frameDocument.documentElement.outerHTML}`;
}
