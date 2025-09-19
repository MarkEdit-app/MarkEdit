import { LanguageModelResponse } from 'markedit-api';
import { applyStreamUpdate } from '../../api/languageModel';
import { WebModule } from '../webModule';

/**
 * @shouldExport true
 * @invokePath foundationModels
 * @overrideModuleName WebBridgeFoundationModels
 */
export interface WebModuleFoundationModels extends WebModule {
  applyStreamUpdate(args: { streamID: string; response: LanguageModelResponse }): void;
}

export class WebModuleFoundationModelsImpl implements WebModuleFoundationModels {
  applyStreamUpdate(args: { streamID: string; response: LanguageModelResponse }): void {
    applyStreamUpdate(args.streamID, args.response);
  }
}
