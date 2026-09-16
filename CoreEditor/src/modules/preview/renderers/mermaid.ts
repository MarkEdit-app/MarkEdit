import type { ModuleLoader } from './loadModule';

interface Mermaid {
  initialize(config: { theme: string; startOnLoad: boolean }): void;
  render(id: string, code: string, container: HTMLElement): Promise<{ svg: string }>;
}

export async function renderMermaid(container: HTMLElement, code: string, loadModule: ModuleLoader): Promise<void> {
  const { default: mermaid } = await loadModule<{ default: Mermaid }>('https://cdn.jsdelivr.net/npm/mermaid@12.0.0/dist/mermaid.esm.min.mjs');
  const theme = matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default';
  mermaid.initialize({ theme, startOnLoad: false });
  container.innerHTML = (await mermaid.render('markedit-diagram', code, container)).svg;
}
