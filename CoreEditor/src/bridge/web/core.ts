import { WebModule } from '../webModule';
import { ReplaceGranularity, resetEditor, clearEditor, getEditorText, insertText, replaceText, markEditorDirty } from '../../core';

/**
 * @shouldExport true
 * @invokePath core
 * @overrideModuleName WebBridgeCore
 */
export interface WebModuleCore extends WebModule {
  resetEditor({ text }: { text: string }): void;
  clearEditor(): void;
  getEditorText(): string;
  insertText({ text, from, to }: { text: string; from: CodeGen_Int; to: CodeGen_Int }): void;
  replaceText({ text, granularity }: { text: string; granularity: ReplaceGranularity }): void;
  markEditorDirty({ isDirty }: { isDirty: boolean }): void;
}

export class WebModuleCoreImpl implements WebModuleCore {
  resetEditor({ text }: { text: string }): void {
    resetEditor(text);
  }

  clearEditor(): void {
    clearEditor();
  }

  getEditorText(): string {
    return getEditorText();
  }

  insertText({ text, from, to }: { text: string; from: CodeGen_Int; to: CodeGen_Int }): void {
    insertText(text, from, to);
  }

  replaceText({ text, granularity }: { text: string; granularity: ReplaceGranularity }): void {
    replaceText(text, granularity);
  }

  markEditorDirty({ isDirty }: { isDirty: boolean }): void {
    markEditorDirty(isDirty);
  }
}
