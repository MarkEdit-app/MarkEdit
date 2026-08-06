import { NativeModule } from '../nativeModule';
import { TextTokenizeAnchor } from '../../modules/tokenizer/types';

/**
 * @shouldExport true
 * @invokePath completion
 * @bridgeName NativeBridgeCompletion
 */
export interface NativeModuleCompletion extends NativeModule {
  requestCompletions(args: { anchor: TextTokenizeAnchor; fullText?: string; userInitiated: boolean }): void;
  commitCompletion({ insert }: { insert?: string }): void;
  cancelCompletion(): void;
  selectPrevious(): void;
  selectNext(): void;
  selectTop(): void;
  selectBottom(): void;
}
