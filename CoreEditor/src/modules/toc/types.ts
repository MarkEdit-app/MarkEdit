export interface HeadingInfo {
  title: string;
  level: CodeGen_Int;
  from: CodeGen_Int;
  to: CodeGen_Int;
  selected: boolean;
  lineNumber: CodeGen_Int;
}

export interface DocumentOutline {
  revision: string;
  text?: string;
  headings: HeadingInfo[];
}
