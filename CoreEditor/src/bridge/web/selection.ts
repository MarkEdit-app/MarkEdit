import { WebModule } from '../webModule';
import { selectedMainText, scrollToSelection, gotoLine } from '../../modules/selection';

/**
 * @shouldExport true
 * @invokePath selection
 * @overrideModuleName WebBridgeSelection
 */
export interface WebModuleSelection extends WebModule {
  getText(): string;
  scrollToSelection(): void;
  gotoLine({ lineNumber }: { lineNumber: CodeGen_Int }): void;
}

export class WebModuleSelectionImpl implements WebModuleSelection {
  getText(): string {
    return selectedMainText();
  }

  scrollToSelection(): void {
    scrollToSelection();
  }

  gotoLine({ lineNumber }: { lineNumber: CodeGen_Int }): void {
    gotoLine(lineNumber);
  }
}
