import { Extension } from '@codemirror/state';

export type ColorScheme = 'light' | 'dark';

export interface BaseColors {
  accent: string;
  text: string;
}

export interface EditorColors {
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
  lineBorder?: string;
  bracketBorder?: string;
}

export interface EditorTheme {
  accentColor: string;
  extension: Extension;
}
