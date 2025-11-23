import { getClientRect } from '../../common/utils';

export enum PreviewType {
  mermaid = 'mermaid',
  katex = 'katex',
  table = 'table',
}

/**
 * Invokes native methods to show code preview.
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

  const pos = target.dataset.pos;
  if (pos === undefined) {
    return;
  }

  const rect = window.editor.coordsAtPos(parseInt(pos));
  if (rect === null) {
    return;
  }

  const type = target.dataset.type as PreviewType;
  window.nativeModules.preview.show({ code, type, rect: getClientRect(rect) });

  cancelDefaultEvent(event);
}

export function cancelDefaultEvent(event: MouseEvent) {
  const target = event.target as HTMLElement;
  if (target.className.includes('cm-md-previewButton')) {
    event.preventDefault();
    event.stopPropagation();
  }
}
