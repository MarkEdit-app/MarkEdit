import { WebModule } from '../webModule';
import { setActive, ensureSelectionRect } from '../../modules/writingTools';

/**
 * @shouldExport true
 * @invokePath writingTools
 * @overrideModuleName WebBridgeWritingTools
 */
export interface WebModuleWritingTools extends WebModule {
  setActive({ isActive, reselect }: { isActive: boolean; reselect: boolean }): void;
  ensureSelectionRect(): void;
}

export class WebModuleWritingToolsImpl implements WebModuleWritingTools {
  setActive({ isActive, reselect }: { isActive: boolean; reselect: boolean }): void {
    setActive(isActive, reselect);
  }

  ensureSelectionRect(): void {
    ensureSelectionRect();
  }
}
