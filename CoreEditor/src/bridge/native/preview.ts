import { NativeModule } from '../nativeModule';
import { PreviewType } from '../../modules/preview';
import { WebRect } from '../../@types/WebRect';

/**
 * @shouldExport true
 * @invokePath preview
 * @bridgeName NativeBridgePreview
 */
export interface NativeModulePreview extends NativeModule {
  show({ code, type, rect }: { code: string; type: PreviewType; rect: WebRect }): void;
}
