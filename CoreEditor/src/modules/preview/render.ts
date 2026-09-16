import { renderMermaid } from './renderers/mermaid';
import { renderKatex } from './renderers/katex';
import { renderTable } from './renderers/table';
import { renderInFrame, type Renderer } from './frame';

export function renderPreview(frame: HTMLIFrameElement, type: string, code: string): void {
  const renderer = rendererForType(type);
  if (renderer === undefined) {
    return;
  }

  renderInFrame(frame, renderer, code);
}

function rendererForType(type: string): Renderer | undefined {
  switch (type) {
    case 'mermaid': return renderMermaid;
    case 'katex': return renderKatex;
    case 'table': return renderTable;
    default: return;
  }
}
