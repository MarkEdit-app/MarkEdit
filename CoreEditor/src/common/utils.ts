import { Rect } from '@codemirror/view';

export const isChrome = /Chrome/.test(navigator.userAgent);
export const isReleaseMode = typeof window.webkit?.messageHandlers === 'object';

export function almostEqual(a: number, b: number) {
  return Math.abs(a - b) < 0.001;
};

export function afterDomUpdate(callback: () => void) {
  setTimeout(callback, 50);
}

export function forceRedrawElement(element: HTMLElement) {
  const visibility = element.style.visibility;
  element.style.visibility = 'hidden';
  afterDomUpdate(() => element.style.visibility = visibility);
}

export function sleep(milliseconds: number) {
  // eslint-disable-next-line compat/compat
  return new Promise(resolve => setTimeout(resolve, milliseconds));
}

export function getFontSizeValue(fontSize: string) {
  // "10px" -> 10
  const match = fontSize.match(/^[0-9.]+/);
  return match ? parseFloat(match[0]) : 0;
}

export function getClientRect(rect: Rect) {
  // If the scale is not 1.0, it means that the viewport is not the actual size (e.g., pinch to zoom),
  // we need to take this into account when getting the rect.
  const scale = getViewportScale();

  return {
    x: rect.left * scale,
    y: rect.top * scale,
    // Client rects with zero width or height are not accepted
    width: Math.max(1, (rect.right - rect.left) * scale),
    height: Math.max(1, (rect.bottom - rect.top) * scale),
  };
}

export function getViewportScale() {
  return window.visualViewport?.scale ?? document.documentElement.clientWidth / window.innerWidth;
}

export function isMetaKey(event: KeyboardEvent) {
  return event.key === 'Meta';
}
