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
  notifyViewDidUpdate({ contentEdited, isDirty, selectedLineColumn }: { contentEdited: boolean; isDirty: boolean; selectedLineColumn: LineColumnInfo }): void;
}
