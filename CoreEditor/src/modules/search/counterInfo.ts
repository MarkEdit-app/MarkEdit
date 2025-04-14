/**
 * Info to show text like "1 of 3".
 */
export default interface SearchCounterInfo {
  /** Total number of matched items */
  numberOfItems: CodeGen_Int;

  /** Index for the selected item, zero-based */
  currentIndex: CodeGen_Int;
}
