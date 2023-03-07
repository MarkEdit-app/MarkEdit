export interface TextTokenizeAnchor {
  text: string;
  pos: CodeGen_Int;
  offset: CodeGen_Int;
}

export interface TextTokenizeResult {
  from: CodeGen_Int;
  to: CodeGen_Int;
}
