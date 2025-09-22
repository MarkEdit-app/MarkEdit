import { LanguageModelAvailability, LanguageModelResponse } from 'markedit-api';
import { applyStreamUpdate } from '../../api/languageModel';
import { WebModule } from '../webModule';

/**
 * @shouldExport true
 * @invokePath foundationModels
 * @overrideModuleName WebBridgeFoundationModels
 */
export interface WebModuleFoundationModels extends WebModule {
  /**
   * Don't call this directly, it does nothing.
   */
  __generateTypes__(_types: { arg0: LanguageModelAvailability }): void;
  applyStreamUpdate(args: { streamID: string; response: LanguageModelResponse }): void;
}

export class WebModuleFoundationModelsImpl implements WebModuleFoundationModels {
  __generateTypes__(_types: { arg0: LanguageModelAvailability }): void {
    // no-op
  }

  applyStreamUpdate(args: { streamID: string; response: LanguageModelResponse }): void {
    applyStreamUpdate(args.streamID, args.response);
  }
}
