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

  const code = target.getAttribute('data-code');
  if (code === null) {
    return;
  }

  const pos = target.getAttribute('data-pos');
  if (pos === null) {
    return;
  }

  const rect = window.editor.coordsAtPos(parseInt(pos));
  if (rect === null) {
    return;
  }

  const type = target.getAttribute('data-type') as PreviewType;
  window.nativeModules.preview.show({
    code, type, rect: {
      x: rect.left,
      y: rect.top,
      width: rect.right - rect.left,
      height: rect.bottom - rect.top,
    },
  });

  event.preventDefault();
  event.stopPropagation();
}
