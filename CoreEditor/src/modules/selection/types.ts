export interface SelectionRange {
  anchor: CodeGen_Int;
  head: CodeGen_Int;
}

export interface LineColumnInfo {
  contentLength: CodeGen_Int;
  lineNumber: CodeGen_Int;
  columnText: string;
  selectionText: string;
  selectionRange?: SelectionRange;
}
