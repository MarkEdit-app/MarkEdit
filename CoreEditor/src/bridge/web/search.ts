import { WebModule } from '../webModule';
import {
  SearchOptions,
  setState,
  updateQuery,
  selectAllOccurrences,
  findNext,
  findPrevious,
  replaceNext,
  replaceAll,
  numberOfMatches,
} from '../../modules/search';

/**
 * @shouldExport true
 * @invokePath search
 * @overrideModuleName WebBridgeSearch
 */
export interface WebModuleSearch extends WebModule {
  setState({ enabled }: { enabled: boolean }): void;
  updateQuery({ options }: { options: SearchOptions }): CodeGen_Int;
  findNext({ search }: { search: string }): void;
  findPrevious({ search }: { search: string }): void;
  replaceNext(): void;
  replaceAll(): void;
  selectAllOccurrences(): void;
  numberOfMatches(): CodeGen_Int;
}

export class WebModuleSearchImpl implements WebModuleSearch {
  setState({ enabled }: { enabled: boolean }): void {
    setState(enabled);
  }

  updateQuery({ options }: { options: SearchOptions }): CodeGen_Int {
    return updateQuery(options) as CodeGen_Int;
  }

  findNext({ search }: { search: string }): void {
    findNext(search);
  }

  findPrevious({ search }: { search: string }): void {
    findPrevious(search);
  }

  replaceNext(): void {
    replaceNext();
  }

  replaceAll(): void {
    replaceAll();
  }

  selectAllOccurrences(): void {
    selectAllOccurrences();
  }

  numberOfMatches(): CodeGen_Int {
    return numberOfMatches();
  }
}
