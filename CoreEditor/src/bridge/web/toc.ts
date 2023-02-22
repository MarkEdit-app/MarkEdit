import { WebModule } from '../webModule';
import { HeadingInfo, getTableOfContents, selectPreviousSection, selectNextSection, gotoHeader } from '../../modules/toc';

/**
 * @shouldExport true
 * @invokePath toc
 * @overrideModuleName WebBridgeTableOfContents
 */
export interface WebModuleTableOfContents extends WebModule {
  getTableOfContents(): HeadingInfo[];
  selectPreviousSection(): void;
  selectNextSection(): void;
  gotoHeader({ headingInfo }: { headingInfo: HeadingInfo }): void;
}

export class WebModuleTableOfContentsImpl implements WebModuleTableOfContents {
  getTableOfContents(): HeadingInfo[] {
    return getTableOfContents();
  }

  selectPreviousSection(): void {
    selectPreviousSection();
  }

  selectNextSection(): void {
    selectNextSection();
  }

  gotoHeader({ headingInfo }: { headingInfo: HeadingInfo }): void {
    gotoHeader(headingInfo);
  }
}
