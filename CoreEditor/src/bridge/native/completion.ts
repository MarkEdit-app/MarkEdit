import { NativeModule } from '../nativeModule';
import { TextTokenizeAnchor } from '../../modules/tokenizer/types';
import { JSRect } from '../../@types/JSRect';

/**
 * @shouldExport true
 * @invokePath completion
 * @bridgeName NativeBridgeCompletion
 */
export interface NativeModuleCompletion extends NativeModule {
  requestCompletions({ anchor, fullText, caretRect }: { anchor: TextTokenizeAnchor; fullText?: string; caretRect: JSRect }): void;
  commitCompletion(): void;
  selectPrevious(): void;
  selectNext(): void;
}
