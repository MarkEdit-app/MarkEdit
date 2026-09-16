import type { ModuleLoader } from './loadModule';

interface Katex {
  renderToString(code: string, options: { throwOnError: boolean; displayMode: boolean }): string;
}

export async function renderKatex(container: HTMLElement, code: string, loadModule: ModuleLoader): Promise<void> {
  const [{ default: katex }] = await Promise.all([
    loadModule<{ default: Katex }>('https://cdn.jsdelivr.net/npm/katex@0.18.7/dist/katex.min.mjs'),
    loadMathStyles(),
  ]);

  container.innerHTML = katex.renderToString(
    code,
    { throwOnError: false, displayMode: true },
  );

  function loadMathStyles(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = 'https://cdn.jsdelivr.net/npm/katex@0.18.7/dist/katex.min.css';
      link.onload = () => resolve();
      link.onerror = () => {
        link.remove();
        reject(new Error('Failed to load KaTeX styles'));
      };

      document.head.appendChild(link);
    });
  }
}
