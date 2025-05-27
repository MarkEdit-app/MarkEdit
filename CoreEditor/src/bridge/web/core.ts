import { WebModule } from '../webModule';
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
  resetEditor({ text }: { text: string }): void;
  clearEditor(): void;
  getEditorState(): { hasFocus: boolean; hasSelection: boolean };
  getEditorText(): string;
  getReadableContentPair(): ReadableContentPair;
  insertText({ text, from, to }: { text: string; from: CodeGen_Int; to: CodeGen_Int }): void;
  replaceText({ text, granularity }: { text: string; granularity: ReplaceGranularity }): void;
  handleFocusLost(): void;
  handleMouseExited({ clientX, clientY }: { clientX: number; clientY: number }): void;
  setHasModalSheet({ value }: { value: boolean }): void;
}

export class WebModuleCoreImpl implements WebModuleCore {
  resetEditor({ text }: { text: string }): void {
    resetEditor(text);
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
