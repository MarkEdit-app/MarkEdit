import { WebModule } from '../webModule';
import { handleMainMenuAction, handleContextMenuAction } from '../../api/ui';

/**
 * @shouldExport true
 * @invokePath api
 * @overrideModuleName WebBridgeAPI
 */
export interface WebModuleAPI extends WebModule {
  handleMainMenuAction({ id }: { id: string }): void;
  handleContextMenuAction({ id }: { id: string }): void;
}

export class WebModuleAPIImpl implements WebModuleAPI {
  handleMainMenuAction({ id }: { id: string }): void {
    handleMainMenuAction(id);
  }

  handleContextMenuAction({ id }: { id: string }): void {
    handleContextMenuAction(id);
  }
}
