import { NativeModule } from '../nativeModule';

/**
 * @shouldExport true
 * @invokePath pdf
 * @bridgeName NativeBridgePDF
 */
export interface NativeModulePDF extends NativeModule {
  generate({ html, fileName }: { html: string; fileName?: string }): Promise<boolean>;
}
