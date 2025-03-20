/**
 * Remove existing list marker from text, e.g., changing "- Item" to "Item".
 */
export default function removeListMarkers(text: string): string {
  return text.replace(/^([-*+] +\[[ xX]\] )|^([-*+] )|^(\d+\. )/, '');
}
