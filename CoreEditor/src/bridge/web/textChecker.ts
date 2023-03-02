import { WebModule } from '../webModule';
import { TextCheckerOptions, update, dismiss } from '../../modules/textChecker';

/**
 * @shouldExport true
 * @invokePath textChecker
 * @overrideModuleName WebBridgeTextChecker
 */
export interface WebModuleTextChecker extends WebModule {
  update({ options }: { options: TextCheckerOptions }): void;
  dismiss(): void;
}

export class WebModuleTextCheckerImpl implements WebModuleTextChecker {
  update({ options }: { options: TextCheckerOptions }): void {
    update(options);
  }

  dismiss(): void {
    dismiss();
  }
}
