import { NativeModule } from '../nativeModule';

/**
 * @shouldExport true
 * @invokePath secretStorage
 * @bridgeName NativeBridgeSecretStorage
 */
export interface NativeModuleSecretStorage extends NativeModule {
  has(args: { capability?: string; key: string }): Promise<string>;
  get(args: { capability?: string; key: string }): Promise<string>;
  set(args: { capability?: string; key: string; value: string }): Promise<string>;
  delete(args: { capability?: string; key: string }): Promise<string>;
}
