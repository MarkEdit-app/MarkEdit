import { NativeModule } from '../nativeModule';
import { TextTokenizeAnchor } from '../../modules/tokenizer/types';

/**
 * @shouldExport true
 * @invokePath tokenizer
 * @bridgeName NativeBridgeTokenizer
 */
export interface NativeModuleTokenizer extends NativeModule {
  tokenize({ anchor }: { anchor: TextTokenizeAnchor }): Promise<string>;
  moveWordBackward({ anchor }: { anchor: TextTokenizeAnchor }): Promise<CodeGen_Int>;
  moveWordForward({ anchor }: { anchor: TextTokenizeAnchor }): Promise<CodeGen_Int>;
}
