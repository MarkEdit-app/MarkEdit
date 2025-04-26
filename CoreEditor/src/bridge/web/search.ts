import { WebModule } from '../webModule';
import {
  SearchOperation,
  SearchOptions,
  SearchCounterInfo,
  setState,
  updateQuery,
  updateHasSelection,
  selectAllOccurrences,
  selectNextOccurrence,
  findNext,
  findPrevious,
  replaceNext,
  replaceAll,
  searchCounterInfo,
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
  updateQuery({ options }: { options: SearchOptions }): void;
  updateHasSelection(): void;
  performOperation({ operation }: { operation: SearchOperation }): void;
  findNext({ search }: { search: string }): boolean;
  findPrevious({ search }: { search: string }): boolean;
  replaceNext(): void;
  replaceAll(): void;
  selectAllOccurrences(): void;
  selectNextOccurrence(): boolean;
  getCounterInfo(): SearchCounterInfo;
}

export class WebModuleSearchImpl implements WebModuleSearch {
  setState({ enabled }: { enabled: boolean }): void {
    setState(enabled);
  }

  updateQuery({ options }: { options: SearchOptions }): void {
    return updateQuery(options);
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

  selectNextOccurrence(): boolean {
    return selectNextOccurrence();
  }

  getCounterInfo(): SearchCounterInfo {
    return searchCounterInfo();
  }
}
