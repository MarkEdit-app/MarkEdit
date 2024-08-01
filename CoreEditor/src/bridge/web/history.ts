import { WebModule } from '../webModule';
import { undo, redo, canUndo, canRedo, markContentClean, setIgnoreBeforeInput } from '../../modules/history';

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
  markContentClean(): void;
  setIgnoreBeforeInput({ value }: { value: boolean }): void;
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

  markContentClean(): void {
    markContentClean();
  }

  setIgnoreBeforeInput({ value }: { value: boolean }): void {
    setIgnoreBeforeInput(value);
  }
}
