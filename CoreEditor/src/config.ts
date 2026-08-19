import { EditorConfig } from 'markedit-api';
import { Compartment } from '@codemirror/state';
import { WebFontFace } from './@types/WebFontFace';

/**
 * @shouldExport true
 * @overrideModuleName EditorHost
 */
export enum Host {
  mainApp = 'mainApp',
  quicklook = 'quicklook',
}

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
export interface Config extends EditorConfig {
  host: Host;
  text: string;
  fontFace: WebFontFace;
  invisiblesBehavior: InvisiblesBehavior;
  tabKeyBehavior?: CodeGen_Int;
  localizable?: Localizable;
  // Runtime config from settings.json, not dynamically changeable
  autoCharacterPairs: boolean;
  indentBehavior: IndentBehavior;
  undoGroupingInterval?: number;
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
