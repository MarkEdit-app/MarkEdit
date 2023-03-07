import { WebModule } from '../webModule';
import { JSRect } from '../../@types/JSRect';
import { selectedMainText, scrollToSelection, getRect, gotoLine } from '../../modules/selection';

/**
 * @shouldExport true
 * @invokePath selection
 * @overrideModuleName WebBridgeSelection
 */
export interface WebModuleSelection extends WebModule {
  getText(): string;
  getRect({ pos }: { pos: CodeGen_Int }): JSRect | undefined;
  scrollToSelection(): void;
  gotoLine({ lineNumber }: { lineNumber: CodeGen_Int }): void;
}

export class WebModuleSelectionImpl implements WebModuleSelection {
  getText(): string {
    return selectedMainText();
  }

  getRect({ pos }: { pos: CodeGen_Int }): JSRect | undefined {
    return getRect(pos);
  }

  scrollToSelection(): void {
    scrollToSelection();
  }

  gotoLine({ lineNumber }: { lineNumber: CodeGen_Int }): void {
    gotoLine(lineNumber);
  }
}
