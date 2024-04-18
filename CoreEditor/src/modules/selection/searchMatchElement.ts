/**
 * Returns the current selected search match or null if not found.
 */
export default function searchMatchElement() {
  return document.querySelector('.cm-searchMatch-selected') as HTMLElement | null;
}
