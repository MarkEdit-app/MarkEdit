import { NativeModule } from '../nativeModule';
import { WebMenuItem } from '../../@types/WebMenuItem';
import { WebPoint } from '../../@types/WebPoint';

/**
 * @shouldExport true
 * @invokePath api
 * @bridgeName NativeBridgeAPI
 */
export interface NativeModuleAPI extends NativeModule {
  getFileInfo(): Promise<string | undefined>;
  addMainMenuItems({ items }: { items: WebMenuItem[] }): void;
  showContextMenu(args: { items: WebMenuItem[]; location: WebPoint }): void;
  showAlert(args: { title?: string; message?: string; buttons?: string[] }): Promise<CodeGen_Int>;
  showTextBox(args: { title?: string; placeholder?: string; defaultValue?: string }): Promise<string | undefined>;
}
