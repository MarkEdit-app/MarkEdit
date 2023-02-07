import { WebModule } from '../webModule';
import { LineEndings, getLineEndings, setLineEndings } from '../../modules/lineEndings';

/**
 * @shouldExport true
 * @invokePath lineEndings
 * @overrideModuleName WebBridgeLineEndings
 */
export interface WebModuleLineEndings extends WebModule {
  getLineEndings(): LineEndings;
  setLineEndings({ lineEndings }: { lineEndings: LineEndings }): void;
}

export class WebModuleLineEndingsImpl implements WebModuleLineEndings {
  getLineEndings(): LineEndings {
    return getLineEndings();
  }

  setLineEndings({ lineEndings }: { lineEndings: LineEndings }): void {
    setLineEndings(lineEndings);
  }
}
