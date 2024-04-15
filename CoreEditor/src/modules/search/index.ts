import { EditorSelection } from '@codemirror/state';
import { SearchQuery, openSearchPanel, closeSearchPanel, setSearchQuery, getSearchQuery } from '@codemirror/search';
import { scrollPositionToVisible, scrollSearchMatchToVisible, selectedMainText } from '../selection';

import SearchOptions from './options';
import matchFromQuery from './matchFromQuery';
import rangesFromQuery from './rangesFromQuery';
import searchOccurrences from './searchOccurrences';
import hasSelection from '../selection/hasSelection';
import selectWithRanges from '../selection/selectWithRanges';

// Imagine this entire file as a front-end to the @codemirror/search module
import * as search from '@codemirror/search';

// Search operations
import {
  SearchOperation,
  performReplaceAll,
  performReplaceAllInSelection,
  performSelectAll,
  performSelectAllInSelection,
} from './operations';

export function setState(enabled: boolean) {
  if (storage.isEnabled === enabled) {
    return;
  }

  if (enabled) {
    storage.enabledWithSelection = hasSelection();
    openSearchPanel(window.editor);
  } else {
    storage.enabledWithSelection = false;
    closeSearchPanel(window.editor);
  }

  storage.isEnabled = enabled;
}

export function updateQuery(options: SearchOptions): number {
  storage.options = options;
  setState(true);

  const editor = window.editor;
  const query = new SearchQuery(options);
  editor.dispatch({ effects: setSearchQuery.of(query) });

  // Get ranges and refocus if needed
  const ranges = rangesFromQuery(query);
  if (options.refocus) {
    // Try ranges in viewport
    for (const range of ranges) {
      const rect = editor.coordsAtPos(range.from);
      if (rect !== null && rect.top >= 0 && rect.top <= editor.dom.clientHeight) {
        if (!storage.enabledWithSelection) {
          editor.dispatch({
            selection: EditorSelection.range(range.from, range.to),
          });
        }

        scrollSearchMatchToVisible(range);
        return ranges.length;
      }
    }

    // Failed to get a range in viewport, try harder
    if (storage.enabledWithSelection) {
      const match = matchFromQuery(query);
      if (match === null) {
        scrollSearchMatchToVisible(ranges.length > 0 ? ranges[0] : undefined);
      } else {
        scrollPositionToVisible(match.from);
      }
    } else {
      (() => findNext(options.search) || findPrevious(options.search))();
    }
  }

  return ranges.length;
}

export function findNext(term: string) {
  prepareNavigation(term);
  const result = search.findNext(window.editor);

  scrollSearchMatchToVisible();
  return result;
}

export function findPrevious(term: string) {
  prepareNavigation(term);
  const result = search.findPrevious(window.editor);

  scrollSearchMatchToVisible();
  return result;
}

export function replaceNext() {
  search.replaceNext(window.editor);
  scrollSearchMatchToVisible();
}

export function replaceAll() {
  performSelectAll();
  scrollSearchMatchToVisible();
}

export function selectAllOccurrences() {
  const doc = window.editor.state.doc.toString();
  const query = selectedMainText();
  if (query.length > 0) {
    selectWithRanges(searchOccurrences(doc, query));
  }
}

export function numberOfMatches(): CodeGen_Int {
  const query = getSearchQuery(window.editor.state);
  const ranges = rangesFromQuery(query);
  return ranges.length as CodeGen_Int;
}

export function hasVisibleSelectedMatch() {
  const element = document.querySelector('.cm-searchMatch-selected') as HTMLElement | null;
  if (element === null) {
    return false;
  }

  const rect = element.getBoundingClientRect();
  return rect.top > 0 && rect.bottom < window.editor.dom.clientHeight;
}

export function performOperation(operation: SearchOperation) {
  const options: SearchOptions = storage.options ?? {
    search: '',
    caseSensitive: false,
    literal: false,
    regexp: false,
    wholeWord: false,
    refocus: false,
  };

  switch (operation) {
    case SearchOperation.selectAll:
      performSelectAll();
      break;
    case SearchOperation.selectAllInSelection:
      performSelectAllInSelection(options);
      break;
    case SearchOperation.replaceAll:
      performReplaceAll();
      break;
    case SearchOperation.replaceAllInSelection:
      performReplaceAllInSelection(options);
      break;
  }

  const selection = window.editor.state.selection.main;
  scrollSearchMatchToVisible(selection);
}

export type { SearchOperation, SearchOptions };

function prepareNavigation(search: string) {
  if (storage.options === undefined) {
    return;
  }

  setState(true);
  storage.options.search = search;

  const query = new SearchQuery(storage.options);
  window.editor.dispatch({ effects: setSearchQuery.of(query) });
}

const storage: {
  isEnabled: boolean;
  enabledWithSelection: boolean;
  options: SearchOptions | undefined;
} = {
  isEnabled: false,
  enabledWithSelection: false,
  options: undefined,
};
