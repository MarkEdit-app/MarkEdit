import { WebModule } from '../webModule';
import {
  SearchOperation,
  SearchOptions,
  setState,
  updateQuery,
  updateHasSelection,
  selectAllOccurrences,
  findNext,
  findPrevious,
  replaceNext,
  replaceAll,
  numberOfMatches,
  hasVisibleSelectedMatch,
  performOperation,
} from '../../modules/search';

/**
 * @shouldExport true
 * @invokePath search
 * @overrideModuleName WebBridgeSearch
 */
export interface WebModuleSearch extends WebModule {
  setState({ enabled }: { enabled: boolean }): void;
  updateQuery({ options }: { options: SearchOptions }): CodeGen_Int;
  updateHasSelection(): void;
  performOperation({ operation }: { operation: SearchOperation }): void;
  findNext({ search }: { search: string }): boolean;
  findPrevious({ search }: { search: string }): boolean;
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

  updateHasSelection(): void {
    updateHasSelection();
  }

  performOperation({ operation }: { operation: SearchOperation }): void {
    performOperation(operation);
  }

  findNext({ search }: { search: string }): boolean {
    const result = hasVisibleSelectedMatch();
    findNext(search);

    return result;
  }

  findPrevious({ search }: { search: string }): boolean {
    const result = hasVisibleSelectedMatch();
    findPrevious(search);

    return result;
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
