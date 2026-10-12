import { WebModule } from '../webModule';
import { DocumentOutline, HeadingInfo, getDocumentOutline, getTableOfContents, selectPreviousSection, selectNextSection, gotoHeader } from '../../modules/toc';

/**
 * @shouldExport true
 * @invokePath toc
 * @overrideModuleName WebBridgeTableOfContents
 */
export interface WebModuleTableOfContents extends WebModule {
  getTableOfContents(): HeadingInfo[];
  getDocumentOutline({ knownRevision }: { knownRevision?: string }): DocumentOutline;
  selectPreviousSection(): void;
  selectNextSection(): void;
  gotoHeader({ headingInfo }: { headingInfo: HeadingInfo }): void;
}

export class WebModuleTableOfContentsImpl implements WebModuleTableOfContents {
  getTableOfContents(): HeadingInfo[] {
    return getTableOfContents();
  }

  getDocumentOutline({ knownRevision }: { knownRevision?: string }): DocumentOutline {
    return getDocumentOutline(knownRevision);
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
