import { NativeModule } from '../nativeModule';
import { LineColumnInfo } from '../../modules/selection/types';

/**
 * @shouldExport true
 * @invokePath core
 * @bridgeName NativeBridgeCore
 */
export interface NativeModuleCore extends NativeModule {
  notifyWindowDidLoad(): void;
  notifyEditorDidBecomeIdle(): void;
  notifyBackgroundColorDidChange({ color }: { color: CodeGen_Int }): void;
  notifyViewportScaleDidChange(): void;
  notifyViewDidUpdate(args: { contentEdited: boolean; compositionEnded: boolean; isDirty: boolean; selectedLineColumn: LineColumnInfo }): void;
  notifyContentHeightDidChange({ bottomPanelHeight }: { bottomPanelHeight: number }): void;
  notifyContentOffsetDidChange(): void;
  notifyCompositionEnded({ selectedLineColumn }: { selectedLineColumn: LineColumnInfo }): void;
  notifyLinkClicked({ link }: { link: string }): void;
}
