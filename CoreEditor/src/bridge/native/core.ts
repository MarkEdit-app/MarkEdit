import { NativeModule } from '../nativeModule';
import { LineColumnInfo } from '../../modules/selection/types';

/**
 * @shouldExport true
 * @invokePath core
 * @bridgeName NativeBridgeCore
 */
export interface NativeModuleCore extends NativeModule {
  notifyWindowDidLoad(): void;
  notifyViewportScaleDidChange(): void;
  notifyViewDidUpdate(args: { contentEdited: boolean; compositionEnded: boolean; isDirty: boolean; selectedLineColumn: LineColumnInfo }): void;
  notifyContentOffsetDidChange(): void;
  notifyCompositionEnded({ selectedLineColumn }: { selectedLineColumn: LineColumnInfo }): void;
  notifyLinkClicked({ link }: { link: string }): void;
}
