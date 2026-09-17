import type { ModuleLoader } from './loadModule';

interface Mermaid {
  initialize(config: { theme: string; startOnLoad: boolean }): void;
  render(id: string, code: string, container: HTMLElement): Promise<{ svg: string }>;
}

export async function renderMermaid(container: HTMLElement, code: string, loadModule: ModuleLoader): Promise<void> {
  const { default: mermaid } = await loadModule<{ default: Mermaid }>('https://cdn.jsdelivr.net/npm/mermaid@12.0.0/dist/mermaid.esm.min.mjs');
  const appearance = matchMedia('(prefers-color-scheme: dark)');
  const draw = async () => {
    const theme = appearance.matches ? 'dark' : 'default';
    mermaid.initialize({ theme, startOnLoad: false });
    container.innerHTML = (await mermaid.render('markedit-diagram', code, container)).svg;
    container.removeAttribute('role');

    const diagram = container.querySelector('svg');
    if (diagram && diagram.viewBox.baseVal.width > 0) {
      diagram.style.width = `${diagram.viewBox.baseVal.width}px`;
    }
  };

  let pending = draw();
  appearance.addEventListener('change', () => {
    const previous = pending;
    pending = (async () => {
      await previous.catch(() => {});
      try {
        await draw();
      } catch (error) {
        container.setAttribute('role', 'alert');
        container.textContent = String(error);
      }
    })();
  });

  await pending;
}
