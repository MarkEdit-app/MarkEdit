import { NativeModule } from '../nativeModule';
import { TextTokenizeAnchor } from '../../modules/tokenizer/types';

/**
 * @shouldExport true
 * @invokePath completion
 * @bridgeName NativeBridgeCompletion
 */
export interface NativeModuleCompletion extends NativeModule {
  requestCompletions({ anchor, fullText }: { anchor: TextTokenizeAnchor; fullText?: string }): void;
  commitCompletion({ insert }: { insert?: string }): void;
  cancelCompletion(): void;
  selectPrevious(): void;
  selectNext(): void;
  selectTop(): void;
  selectBottom(): void;
}
