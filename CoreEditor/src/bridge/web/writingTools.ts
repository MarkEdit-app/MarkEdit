import { WebModule } from '../webModule';
import { WebRect } from '../../@types/WebRect';
import { setActive, getSelectionRect, ensureSelectionRect } from '../../modules/writingTools';

/**
 * @shouldExport true
 * @invokePath writingTools
 * @overrideModuleName WebBridgeWritingTools
 */
export interface WebModuleWritingTools extends WebModule {
  setActive({ isActive }: { isActive: boolean }): void;
  getSelectionRect(): WebRect | undefined;
  ensureSelectionRect(): void;
}

export class WebModuleWritingToolsImpl implements WebModuleWritingTools {
  setActive({ isActive }: { isActive: boolean }): void {
    setActive(isActive);
  }

  getSelectionRect(): WebRect | undefined {
    return getSelectionRect();
  }

  ensureSelectionRect(): void {
    ensureSelectionRect();
  }
}
