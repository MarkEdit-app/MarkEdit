import { Rect } from '@codemirror/view';

export function getJSRect(rect: Rect) {
  return {
    x: rect.left,
    y: rect.top,
    width: rect.right - rect.left,
    height: rect.bottom - rect.top,
  };
}
