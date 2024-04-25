import { WebModule } from '../webModule';
import { startCompletion, setPanelVisible, acceptInlinePrediction } from '../../modules/completion';

/**
 * @shouldExport true
 * @invokePath completion
 * @overrideModuleName WebBridgeCompletion
 */
export interface WebModuleCompletion extends WebModule {
  startCompletion({ afterDelay }: { afterDelay: number }): void;
  setState({ panelVisible }: { panelVisible: boolean }): void;
  acceptInlinePrediction(): void;
}

export class WebModuleCompletionImpl implements WebModuleCompletion {
  startCompletion({ afterDelay }: { afterDelay: number }): void {
    startCompletion({ afterDelay });
  }

  setState({ panelVisible }: { panelVisible: boolean }): void {
    setPanelVisible(panelVisible);
  }

  acceptInlinePrediction(): void {
    acceptInlinePrediction();
  }
}
