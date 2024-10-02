import { WebModule } from '../webModule';
import { IndentBehavior } from '../../config';

/**
 * @shouldExport true
 * @invokePath dummy
 * @overrideModuleName WebBridgeDummy
 */
export interface WebModuleDummy extends WebModule {
  /**
   * Don't call this directly, it does nothing.
   *
   * We use this to generate types that are not covered in exposed interfaces, as a workaround.
   */
  __generateTypes__(_types: { arg0: IndentBehavior }): void;
}

export class WebModuleDummyImpl implements WebModuleDummy {
  __generateTypes__(_types: { arg0: IndentBehavior }): void {
    // no-op
  }
}
