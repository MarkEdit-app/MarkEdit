import { WebModule } from '../webModule';
import { startCompletion, setPanelVisible } from '../../modules/completion';

/**
 * @shouldExport true
 * @invokePath completion
 * @overrideModuleName WebBridgeCompletion
 */
export interface WebModuleCompletion extends WebModule {
  startCompletion(): void;
  setState({ panelVisible }: { panelVisible: boolean }): void;
}

export class WebModuleCompletionImpl implements WebModuleCompletion {
  startCompletion(): void {
    startCompletion();
  }

  setState({ panelVisible }: { panelVisible: boolean }): void {
    setPanelVisible(panelVisible);
  }
}
