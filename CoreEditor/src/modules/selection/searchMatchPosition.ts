/**
 * Returns the current selected search match or null if not found.
 */
export default function searchMatchPosition() {
  const element = (document.querySelector('.cm-searchMatch-selected') as HTMLElement | null) ?? (document.querySelector('.cm-searchMatch') as HTMLElement | null);
  if (element === null) {
    return null;
  }

  return window.editor.posAtDOM(element);
}
