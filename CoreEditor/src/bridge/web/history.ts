import { WebModule } from '../webModule';
import { undo, redo, canUndo, canRedo, saveHistory } from '../../modules/history';

/**
 * @shouldExport true
 * @invokePath history
 * @overrideModuleName WebBridgeHistory
 */
export interface WebModuleHistory extends WebModule {
  undo(): void;
  redo(): void;
  canUndo(): boolean;
  canRedo(): boolean;
  saveHistory(): void;
}

export class WebModuleHistoryImpl implements WebModuleHistory {
  undo(): void {
    undo();
  }

  redo(): void {
    redo();
  }

  canUndo(): boolean {
    return canUndo();
  }

  canRedo(): boolean {
    return canRedo();
  }

  saveHistory(): void {
    saveHistory();
  }
}
