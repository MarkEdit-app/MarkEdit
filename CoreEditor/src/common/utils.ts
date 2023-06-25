import { Rect } from '@codemirror/view';

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
