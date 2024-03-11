import { EditorView, Rect } from '@codemirror/view';

export function disableMaybeCreateCompositionBarrier(editor: EditorView) {
  // This hack stops the madness of inline predictions in headings,
  // it was a regression introduced in: https://github.com/codemirror/view/commit/4e355eab50de94ab315ed293729f5365841fe3c8.
  //
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const docView = (editor as any).docView;
  if (typeof docView === 'object' && typeof docView.maybeCreateCompositionBarrier === 'function') {
    docView.maybeCreateCompositionBarrier = () => false;
    return true;
  }

  return false;
}

export function getClientRect(rect: Rect) {
  // If the scale is not 1.0, it means that the viewport is not the actual size (e.g., pinch to zoom),
  // we need to take this into account when getting the rect.
  const scale = getViewportScale();

  return {
    x: rect.left * scale,
    y: rect.top * scale,
    width: (rect.right - rect.left) * scale,
    height: (rect.bottom - rect.top) * scale,
  };
}

export function getViewportScale() {
  return window.visualViewport?.scale ?? document.documentElement.clientWidth / window.innerWidth;
}
