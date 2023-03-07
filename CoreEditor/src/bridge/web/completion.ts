import { WebModule } from '../webModule';
import { startCompletion, setPanelVisible } from '../../modules/completion';

/**
 * @shouldExport true
 * @invokePath completion
 * @overrideModuleName WebBridgeCompletion
 */
export interface WebModuleCompletion extends WebModule {
  startCompletion({ afterDelay }: { afterDelay: number }): void;
  setState({ panelVisible }: { panelVisible: boolean }): void;
}

export class WebModuleCompletionImpl implements WebModuleCompletion {
  startCompletion({ afterDelay }: { afterDelay: number }): void {
    startCompletion({ afterDelay });
  }

  setState({ panelVisible }: { panelVisible: boolean }): void {
    setPanelVisible(panelVisible);
  }
}
