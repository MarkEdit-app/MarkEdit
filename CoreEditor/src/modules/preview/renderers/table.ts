import type { ModuleLoader } from './loadModule';

interface Marked {
  parse(code: string): string | Promise<string>;
}

interface DOMPurify {
  sanitize(html: string, config: {
    USE_PROFILES: { html: boolean };
    FORBID_TAGS: string[];
    FORBID_ATTR: string[];
    SANITIZE_NAMED_PROPS: boolean;
  }): string;
}

export async function renderTable(container: HTMLElement, code: string, loadModule: ModuleLoader): Promise<void> {
  const [{ marked }, { default: purify }] = await Promise.all([
    loadModule<{ marked: Marked }>('https://cdn.jsdelivr.net/npm/marked@18.0.13/lib/marked.esm.js'),
    loadModule<{ default: DOMPurify }>('https://cdn.jsdelivr.net/npm/dompurify@3.4.15/dist/purify.es.mjs'),
  ]);

  container.innerHTML = purify.sanitize(await marked.parse(code), {
    USE_PROFILES: { html: true },
    FORBID_TAGS: ['style'],
    FORBID_ATTR: ['style'],
    SANITIZE_NAMED_PROPS: true,
  });
}
