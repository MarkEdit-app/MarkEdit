import { WebModule } from '../webModule';
import { notifyAppReady } from '../../api/methods';
import { handleMainMenuAction, handleContextMenuAction, getMenuItemState, MenuItemState } from '../../api/ui';

/**
 * @shouldExport true
 * @invokePath api
 * @overrideModuleName WebBridgeAPI
 */
export interface WebModuleAPI extends WebModule {
  notifyAppReady(): void;
  handleMainMenuAction({ id }: { id: string }): void;
  handleContextMenuAction({ id }: { id: string }): void;
  getMenuItemState({ id }: { id: string }): MenuItemState;
}

export class WebModuleAPIImpl implements WebModuleAPI {
  notifyAppReady(): void {
    notifyAppReady();
  }

  handleMainMenuAction({ id }: { id: string }): void {
    handleMainMenuAction(id);
  }

  handleContextMenuAction({ id }: { id: string }): void {
    handleContextMenuAction(id);
  }

  getMenuItemState({ id }: { id: string }): MenuItemState {
    return getMenuItemState(id);
  }
}
