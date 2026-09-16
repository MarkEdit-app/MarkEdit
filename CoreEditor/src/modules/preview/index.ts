import { renderPreview } from './render';
import createPreviewOverlay from './overlay';

export enum PreviewType {
  mermaid = 'mermaid',
  katex = 'katex',
  table = 'table',
}

/**
 * Shows a focused preview over the editor.
 */
export function showPreview(event: MouseEvent) {
  const target = event.target as HTMLSpanElement;
  if (!(target instanceof HTMLSpanElement)) {
    return;
  }

  const code = target.dataset.code;
  if (code === undefined) {
    return;
  }

  const type = target.dataset.type as PreviewType;
  if (!Object.values(PreviewType).includes(type)) {
    return;
  }

  const overlay = createPreviewOverlay(type);
  if (overlay === undefined) {
    return;
  }

  cancelDefaultEvent(event);
  void renderPreview(overlay, type, code);
}

export function cancelDefaultEvent(event: MouseEvent) {
  const target = event.target as HTMLElement | null;
  if (target === null) {
    return;
  }

  if (target.className.includes('cm-md-previewButton')) {
    event.preventDefault();
    event.stopPropagation();
  }
}
