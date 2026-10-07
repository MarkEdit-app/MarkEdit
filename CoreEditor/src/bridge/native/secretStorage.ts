import { NativeModule } from '../nativeModule';

/**
 * @shouldExport true
 * @invokePath secretStorage
 * @bridgeName NativeBridgeSecretStorage
 */
export interface NativeModuleSecretStorage extends NativeModule {
  has(args: { path: string; key: string }): Promise<string>;
  get(args: { path: string; key: string }): Promise<string>;
  set(args: { path: string; key: string; value: string }): Promise<string>;
  delete(args: { path: string; key: string }): Promise<string>;
}
