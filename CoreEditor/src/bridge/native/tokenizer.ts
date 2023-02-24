import { NativeModule } from '../nativeModule';
import { TextTokenizeAnchor, TextTokenizeResult } from '../../modules/tokenizer/types';

/**
 * @shouldExport true
 * @invokePath tokenizer
 * @bridgeName NativeBridgeTokenizer
 */
export interface NativeModuleTokenizer extends NativeModule {
  tokenize({ anchor }: { anchor: TextTokenizeAnchor }): Promise<TextTokenizeResult>;
}
