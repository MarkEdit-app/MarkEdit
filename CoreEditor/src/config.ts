import { Compartment } from '@codemirror/state';

/**
 * @shouldExport true
 * @overrideModuleName EditorLocalizable
 */
export interface Localizable {
  // CodeMirror
  controlCharacter: string;
  foldedLines: string;
  unfoldedLines: string;
  foldedCode: string;
  unfold: string;
  foldLine: string;
  unfoldLine: string;
  // Others
  previewButtonTitle: string;
  cmdClickToOpenLink: string;
}

/**
 * @shouldExport true
 * @overrideModuleName EditorInvisiblesBehavior
 */
export enum InvisiblesBehavior {
  never = 'never',
  selection = 'selection',
  trailing = 'trailing',
  always = 'always',
}

/**
 * @shouldExport true
 * @overrideModuleName EditorConfig
 */
export interface Config {
  text: string;
  theme: string;
  fontFamily: string;
  fontSize: number;
  showLineNumbers: boolean;
  showActiveLineIndicator: boolean;
  invisiblesBehavior: InvisiblesBehavior;
  typewriterMode: boolean;
  focusMode: boolean;
  lineWrapping: boolean;
  lineHeight: number;
  suggestWhileTyping: boolean;
  defaultLineBreak?: string;
  tabKeyBehavior?: CodeGen_Int;
  indentUnit?: string;
  localizable?: Localizable;
}

/**
 * Dynamic configurations that can be reconfigured.
 */
export interface Dynamics {
  theme: Compartment;
  gutters?: Compartment;
  invisibles?: Compartment;
  activeLine?: Compartment;
  selectedLines?: Compartment;
  lineWrapping?: Compartment;
  lineEndings?: Compartment;
  indentUnit?: Compartment;
  selectionHighlight?: Compartment;
}
