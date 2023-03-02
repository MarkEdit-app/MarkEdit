import { Rect } from '@codemirror/view';

export const isProd = import.meta.env.PROD;
export const isWebKit = typeof window.webkit === 'object';

export function getJSRect(rect: Rect) {
  return {
    x: rect.left,
    y: rect.top,
    width: rect.right - rect.left,
    height: rect.bottom - rect.top,
  };
}
