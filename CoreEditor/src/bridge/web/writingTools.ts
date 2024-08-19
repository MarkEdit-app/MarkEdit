import { WebModule } from '../webModule';
import { WebRect } from '../../@types/WebRect';
import { setActive, getSelectionRect, ensureSelectionRect } from '../../modules/writingTools';

/**
 * @shouldExport true
 * @invokePath writingTools
 * @overrideModuleName WebBridgeWritingTools
 */
export interface WebModuleWritingTools extends WebModule {
  setActive({ isActive, requestedTool }: { isActive: boolean; requestedTool: CodeGen_Int }): void;
  getSelectionRect(): WebRect | undefined;
  ensureSelectionRect(): void;
}

export class WebModuleWritingToolsImpl implements WebModuleWritingTools {
  setActive({ isActive, requestedTool }: { isActive: boolean; requestedTool: CodeGen_Int }): void {
    setActive(isActive, requestedTool);
  }

  getSelectionRect(): WebRect | undefined {
    return getSelectionRect();
  }

  ensureSelectionRect(): void {
    ensureSelectionRect();
  }
}
