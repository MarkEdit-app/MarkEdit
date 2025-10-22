import { SavePanelOptions } from 'markedit-api';
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
  getPasteboardItems(): Promise<string | undefined>;
  getPasteboardString(): Promise<string | undefined>;
  addMainMenuItems({ items }: { items: WebMenuItem[] }): void;
  showContextMenu(args: { items: WebMenuItem[]; location: WebPoint }): void;
  showAlert(args: { title?: string; message?: string; buttons?: string[] }): Promise<CodeGen_Int>;
  showTextBox(args: { title?: string; placeholder?: string; defaultValue?: string }): Promise<string | undefined>;
  showSavePanel({ options }: { options: SavePanelOptions }): Promise<boolean>;
  runService({ name, input }: { name: string; input?: string }): Promise<boolean>;
}
