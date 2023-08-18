import { Extension } from '@codemirror/state';

export type ColorScheme = 'light' | 'dark';

export interface EditorColors {
  accent: string;
  text: string;
  comment: string;
  background: string;
  caret: string;
  selection: string;
  activeLine: string;
  matchingBracket: string;
  lineNumber: string;
  searchMatch: string;
  selectionHighlight: string;
  visibleSpace: string;
  lighterBackground: string;
  diffAdded: string;
  diffRemoved: string;
  lineBorder?: string;
  bracketBorder?: string;
}

export interface EditorTheme {
  colors: EditorColors;
  extension: Extension;
}
