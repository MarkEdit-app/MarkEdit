import { WebModule } from '../webModule';
import { SelectionRange } from '../../modules/selection/types';

import {
  ReadableContentPair,
  ReplaceGranularity,
  resetEditor,
  clearEditor,
  getEditorState,
  getEditorText,
  getReadableContentPair,
  insertText,
  replaceText,
  performTextDrop,
  handleFocusLost,
  handleMouseExited,
  setHasModalSheet,
} from '../../core';

/**
 * @shouldExport true
 * @invokePath core
 * @overrideModuleName WebBridgeCore
 */
export interface WebModuleCore extends WebModule {
  resetEditor({ text, selectionRange }: { text: string; selectionRange?: SelectionRange }): void;
  clearEditor(): void;
  getEditorState(): { hasFocus: boolean; hasSelection: boolean };
  getEditorText(): string;
  getReadableContentPair(): ReadableContentPair;
  insertText({ text, from, to }: { text: string; from: CodeGen_Int; to: CodeGen_Int }): void;
  replaceText({ text, granularity }: { text: string; granularity: ReplaceGranularity }): void;
  performTextDrop({ text }: { text: string }): void;
  handleFocusLost(): void;
  handleMouseExited({ clientX, clientY }: { clientX: number; clientY: number }): void;
  setHasModalSheet({ value }: { value: boolean }): void;
}

export class WebModuleCoreImpl implements WebModuleCore {
  resetEditor({ text, selectionRange }: { text: string; selectionRange?: SelectionRange }): void {
    resetEditor(text, selectionRange);
  }

  clearEditor(): void {
    clearEditor();
  }

  getEditorState(): { hasFocus: boolean; hasSelection: boolean } {
    return getEditorState();
  }

  getEditorText(): string {
    return getEditorText();
  }

  getReadableContentPair(): ReadableContentPair {
    return getReadableContentPair();
  }

  insertText({ text, from, to }: { text: string; from: CodeGen_Int; to: CodeGen_Int }): void {
    insertText(text, from, to);
  }

  replaceText({ text, granularity }: { text: string; granularity: ReplaceGranularity }): void {
    replaceText(text, granularity);
  }

  performTextDrop({ text }: { text: string }): void {
    performTextDrop(text);
  }

  handleFocusLost(): void {
    handleFocusLost();
  }

  handleMouseExited({ clientX, clientY }: { clientX: number; clientY: number }): void {
    handleMouseExited(clientX, clientY);
  }

  setHasModalSheet({ value }: { value: boolean }): void {
    setHasModalSheet(value);
  }
}
