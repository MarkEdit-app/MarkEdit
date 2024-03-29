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

export function notifyBackgroundColor() {
  const element = window.editor.dom;
  const color = getComputedStyle(element).backgroundColor;
  const match = color.match(/rgb\( *(\d+), *(\d+), *(\d+) *\)/);
  if (match === null) {
    return console.error(`Invalid background color: ${color}`);
  }

  const toHex = (value: string) => parseInt(value).toString(16).padStart(2, '0');
  const red = toHex(match[1]), green = toHex(match[2]), blue = toHex(match[3]);

  // Change it back to number because we only have parsers to handle numbers in native
  const code = parseInt(`${red}${green}${blue}`, 16) as CodeGen_Int;
  window.nativeModules.core.notifyBackgroundColorDidChange({ color: code });
}
