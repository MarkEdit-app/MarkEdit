import { WebModule } from '../webModule';
import { handleMainMenuAction, handleContextMenuAction } from '../../api/ui';

/**
 * @shouldExport true
 * @invokePath ui
 * @overrideModuleName WebBridgeUI
 */
export interface WebModuleUI extends WebModule {
  handleMainMenuAction({ id }: { id: string }): void;
  handleContextMenuAction({ id }: { id: string }): void;
}

export class WebModuleUIImpl implements WebModuleUI {
  handleMainMenuAction({ id }: { id: string }): void {
    handleMainMenuAction(id);
  }

  handleContextMenuAction({ id }: { id: string }): void {
    handleContextMenuAction(id);
  }
}
