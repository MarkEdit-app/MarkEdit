import { Compartment } from '@codemirror/state';
import { WebFontFace } from './@types/WebFontFace';

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
  cmdClickToFollow: string;
  cmdClickToToggleTodo: string;
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
 * @overrideModuleName EditorIndentBehavior
 */
export enum IndentBehavior {
  never = 'never',
  paragraph = 'paragraph',
  line = 'line',
}

/**
 * @shouldExport true
 * @overrideModuleName EditorConfig
 */
export interface Config {
  text: string;
  theme: string; // MarkEdit-theming relies on this, add a fallback if renaming becomes necessary
  fontFace: WebFontFace;
  fontSize: number;
  showLineNumbers: boolean;
  showActiveLineIndicator: boolean;
  invisiblesBehavior: InvisiblesBehavior;
  readOnlyMode: boolean;
  typewriterMode: boolean;
  focusMode: boolean;
  lineWrapping: boolean;
  lineHeight: number;
  suggestWhileTyping: boolean;
  standardDirectories: { [key: string]: string };
  defaultLineBreak?: string;
  tabKeyBehavior?: CodeGen_Int;
  indentUnit?: string;
  localizable?: Localizable;
  // Runtime config from settings.json, not dynamically changeable
  autoCharacterPairs: boolean;
  indentBehavior: IndentBehavior;
  headerFontSizeDiffs?: number[];
  visibleWhitespaceCharacter?: string;
  visibleLineBreakCharacter?: string;
  searchNormalizers?: { [key: string]: string };
}

/**
 * Dynamic configurations that can be reconfigured.
 */
export interface Dynamics {
  theme: Compartment;
  readOnly?: Compartment;
  gutters?: Compartment;
  invisibles?: Compartment;
  activeLine?: Compartment;
  selectedLines?: Compartment;
  lineWrapping?: Compartment;
  lineEndings?: Compartment;
  indentUnit?: Compartment;
  selectionHighlight?: Compartment;
  extensionConfigurator?: Compartment;
  markdownConfigurator?: Compartment;
}

export type { WebFontFace };
