// Imagine this entire file as a front-end to the @codemirror/search module
import {
  findNext as findNextCommand,
  findPrevious as findPreviousCommand,
  replaceNext as replaceNextCommand,
  selectNextOccurrence as selectNextOccurrenceCommand,
} from '@codemirror/search';

import { Command } from '@codemirror/view';
import { EditorSelection, SelectionRange } from '@codemirror/state';
import { SearchQuery, openSearchPanel, closeSearchPanel, setSearchQuery, getSearchQuery } from '@codemirror/search';
import { isElementVisible, isPositionVisible, scrollIntoView, scrollSearchMatchToVisible, selectedMainText } from '../selection';

import SearchOptions from './options';
import SearchCounterInfo from './counterInfo';
import matchFromQuery from './matchFromQuery';
import rangesFromQuery from './rangesFromQuery';
import searchOccurrences from './searchOccurrences';
import hasSelection from '../selection/hasSelection';
import searchMatchElement from '../selection/searchMatchElement';
import selectWithRanges from '../selection/selectWithRanges';

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
    openSearchPanel(window.editor);
  } else {
    closeSearchPanel(window.editor);
  }

  storage.isEnabled = enabled;
}

export function updateQuery(options: SearchOptions) {
  storage.options = options;
  setState(true);

  const editor = window.editor;
  const query = new SearchQuery(options);
  editor.dispatch({
    effects: setSearchQuery.of(query),
  });

  const reselect = (selection: SelectionRange) => {
    if (!storage.hasSelection) {
      editor.dispatch({ selection });
    }
  };

  // Get ranges and refocus if needed
  const ranges = rangesFromQuery(query);
  if (options.refocus) {
    // Try ranges in viewport
    for (const range of ranges) {
      if (isPositionVisible(range.from)) {
        reselect(EditorSelection.range(range.from, range.to));
        return;
      }
    }

    // Failed to get a range in viewport, try harder
    if (storage.hasSelection) {
      const anchor = matchFromQuery(query)?.from ?? (ranges.length > 0 ? ranges[0].from : undefined);
      if (anchor !== undefined) {
        scrollIntoView(anchor, 'center');
      }
    } else {
      const nextFound = findNext(options.search) || findPrevious(options.search);
      if (!nextFound && ranges.length === 0) {
        // Cancel selection when nothing was found
        const cursor = editor.state.selection.main.to;
        reselect(EditorSelection.cursor(cursor));
      }
    }
  }
}

export function updateHasSelection() {
  storage.hasSelection = hasSelection();
}

export function findNext(term: string) {
  return performFindCommand(findNextCommand, term, 'forward');
}

export function findPrevious(term: string) {
  return performFindCommand(findPreviousCommand, term, 'backward');
}

export function replaceNext() {
  replaceNextCommand(window.editor);
  scrollSearchMatchToVisible();
}

export function replaceAll() {
  performReplaceAll();
  scrollSearchMatchToVisible();
}

export function selectAllOccurrences() {
  const doc = window.editor.state.doc.toString();
  const query = selectedMainText();
  if (query.length > 0) {
    selectWithRanges(searchOccurrences(doc, query));
  }
}

export function selectNextOccurrence() {
  const editor = window.editor;
  const oldRanges = editor.state.selection.ranges;
  const foundNext = selectNextOccurrenceCommand(editor);

  const newRanges = editor.state.selection.ranges;
  newRanges.forEach(range => {
    if (!oldRanges.includes(range)) {
      scrollIntoView(range, 'center');
    }
  });

  return foundNext;
}

export function searchCounterInfo(): SearchCounterInfo {
  return {
    numberOfItems: getQueryRanges().length as CodeGen_Int,
    currentIndex: currentMatchIndex() as CodeGen_Int,
  };
}

export function hasVisibleSelectedMatch() {
  const element = searchMatchElement();
  return element !== null && isElementVisible(element);
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

  scrollSearchMatchToVisible();
}

export type { SearchOperation, SearchOptions, SearchCounterInfo };

function prepareNavigation(search: string) {
  if (storage.options === undefined) {
    return;
  }

  setState(true);
  storage.options.search = search;

  const query = new SearchQuery(storage.options);
  window.editor.dispatch({ effects: setSearchQuery.of(query) });
}

function performFindCommand(command: Command, term: string, direction: 'forward' | 'backward') {
  prepareNavigation(term);
  const matches = [...document.querySelectorAll('.cm-searchMatch')].filter(node => isElementVisible(node));
  const index = matches.findIndex(node => node.classList.contains('cm-searchMatch-selected'));
  const boundary = direction === 'backward' ? 0 : (matches.length - 1);
  const result = command(window.editor);

  // We need to scroll when we don't have a visible match, or the next/previous one is not visible
  if (matches.length === 0 || (index === boundary && getQueryRanges().length > 1)) {
    scrollSearchMatchToVisible();
  }

  return result;
}

function getQueryRanges(query?: SearchQuery) {
  return rangesFromQuery(query ?? getSearchQuery(window.editor.state));
}

function currentMatchIndex() {
  const element = document.querySelector('.cm-searchMatch-selected') as HTMLElement | null;
  if (element === null) {
    return -1;
  }

  const position = window.editor.posAtDOM(element);
  const ranges = getQueryRanges();
  return ranges.findIndex(({ from, to }) => from <= position && to >= position);
}

const storage: {
  isEnabled: boolean;
  hasSelection: boolean;
  options: SearchOptions | undefined;
} = {
  isEnabled: false,
  hasSelection: false,
  options: undefined,
};
