import { WebModule } from '../webModule';
import { WebRect } from '../../@types/WebRect';
import { setActive, getSelectionRect } from '../../modules/writingTools';

/**
 * @shouldExport true
 * @invokePath writingTools
 * @overrideModuleName WebBridgeWritingTools
 */
export interface WebModuleWritingTools extends WebModule {
  setActive({ isActive, requestedTool }: { isActive: boolean; requestedTool: CodeGen_Int }): void;
  getSelectionRect(): WebRect | undefined;
}

export class WebModuleWritingToolsImpl implements WebModuleWritingTools {
  setActive({ isActive, requestedTool }: { isActive: boolean; requestedTool: CodeGen_Int }): void {
    setActive(isActive, requestedTool);
  }

  getSelectionRect(): WebRect | undefined {
    return getSelectionRect();
  }
}
