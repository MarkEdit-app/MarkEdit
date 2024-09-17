import { WebModule } from '../webModule';
import { WebRect } from '../../@types/WebRect';
import { selectedMainText, scrollToSelection, getRect, gotoLine, refreshEditFocus, scrollToBottomSmoothly } from '../../modules/selection';
import { navigateGoBack } from '../../modules/selection/navigate';

/**
 * @shouldExport true
 * @invokePath selection
 * @overrideModuleName WebBridgeSelection
 */
export interface WebModuleSelection extends WebModule {
  getText(): string;
  getRect({ pos }: { pos: CodeGen_Int }): WebRect | undefined;
  scrollToSelection(): void;
  gotoLine({ lineNumber }: { lineNumber: CodeGen_Int }): void;
  refreshEditFocus(): void;
  scrollToBottomSmoothly(): void;
  navigateGoBack(): void;
}

export class WebModuleSelectionImpl implements WebModuleSelection {
  getText(): string {
    return selectedMainText();
  }

  getRect({ pos }: { pos: CodeGen_Int }): WebRect | undefined {
    return getRect(pos);
  }

  scrollToSelection(): void {
    scrollToSelection();
  }

  gotoLine({ lineNumber }: { lineNumber: CodeGen_Int }): void {
    gotoLine(lineNumber);
  }

  refreshEditFocus(): void {
    refreshEditFocus();
  }

  scrollToBottomSmoothly(): void {
    scrollToBottomSmoothly();
  }

  navigateGoBack(): void {
    navigateGoBack();
  }
}
