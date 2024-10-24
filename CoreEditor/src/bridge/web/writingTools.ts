import { WebModule } from '../webModule';
import { WebRect } from '../../@types/WebRect';
import { setActive, getSelectionRect, ensureSelectionRect } from '../../modules/writingTools';

/**
 * @shouldExport true
 * @invokePath writingTools
 * @overrideModuleName WebBridgeWritingTools
 */
export interface WebModuleWritingTools extends WebModule {
  setActive({ isActive, reselect }: { isActive: boolean; reselect: boolean }): void;
  getSelectionRect({ reselect }: { reselect: boolean }): WebRect | undefined;
  ensureSelectionRect(): void;
}

export class WebModuleWritingToolsImpl implements WebModuleWritingTools {
  setActive({ isActive, reselect }: { isActive: boolean; reselect: boolean }): void {
    setActive(isActive, reselect);
  }

  getSelectionRect({ reselect }: { reselect: boolean }): WebRect | undefined {
    return getSelectionRect(reselect);
  }

  ensureSelectionRect(): void {
    ensureSelectionRect();
  }
}
