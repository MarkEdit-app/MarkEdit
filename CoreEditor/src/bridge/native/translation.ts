import { NativeModule } from '../nativeModule';

/**
 * @shouldExport true
 * @invokePath translation
 * @bridgeName NativeBridgeTranslation
*/
export interface NativeModuleTranslation extends NativeModule {
  translate(args: { text: string; from?: string; to?: string }): Promise<string>;
}
