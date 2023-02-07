import { NativeModule } from '../nativeModule';
import { PreviewType } from '../../modules/preview';
import { JSRect } from '../../@types/JSRect';

/**
 * @shouldExport true
 * @invokePath preview
 * @bridgeName NativeBridgePreview
 */
export interface NativeModulePreview extends NativeModule {
  show({ code, type, rect }: { code: string; type: PreviewType; rect: JSRect }): void;
}
