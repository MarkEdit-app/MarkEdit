/**
 * Calculate the font size, take headers into account.
 *
 * For example, if the regular font size is 15, "# Heading 1" goes with 20 (15 + 5) by default.
 *
 * @param level Heading level
 * @returns Font size for a *possible* header
 */
export function calculateFontSize(fontSize: number, level: number) {
  const diffs = window.config.headerFontSizeDiffs ?? [5, 3, 1];
  return fontSize + ([0, ...diffs][level] || 0);
}
