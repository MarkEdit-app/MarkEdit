import { WebModule } from '../webModule';
import { resetEditor, clearEditor, getEditorText, markEditorDirty } from '../../core';

/**
 * @shouldExport true
 * @invokePath core
 * @overrideModuleName WebBridgeCore
 */
export interface WebModuleCore extends WebModule {
  resetEditor({ text }: { text: string }): void;
  clearEditor(): void;
  getEditorText(): string;
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

  markEditorDirty({ isDirty }: { isDirty: boolean }): void {
    markEditorDirty(isDirty);
  }
}
