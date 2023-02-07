import { WebModule } from '../webModule';
import { HeadingInfo, getTableOfContents, gotoHeader } from '../../modules/toc';

/**
 * @shouldExport true
 * @invokePath toc
 * @overrideModuleName WebBridgeTableOfContents
 */
export interface WebModuleTableOfContents extends WebModule {
  getTableOfContents(): HeadingInfo[];
  gotoHeader({ headingInfo }: { headingInfo: HeadingInfo }): void;
}

export class WebModuleTableOfContentsImpl implements WebModuleTableOfContents {
  getTableOfContents(): HeadingInfo[] {
    return getTableOfContents();
  }

  gotoHeader({ headingInfo }: { headingInfo: HeadingInfo }): void {
    gotoHeader(headingInfo);
  }
}
