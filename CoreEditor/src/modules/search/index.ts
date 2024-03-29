import { EditorSelection } from '@codemirror/state';
import { SearchQuery, openSearchPanel, closeSearchPanel, setSearchQuery, getSearchQuery } from '@codemirror/search';
import { scrollSearchMatchToVisible, selectedMainText } from '../selection';

import SearchOptions from './options';
import rangesFromQuery from './rangesFromQuery';
import searchOccurrences from './searchOccurrences';
import selectWithRanges from '../selection/selectWithRanges';

// Imagine this entire file as a front-end to the @codemirror/search module
import * as search from '@codemirror/search';

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

export function updateQuery(options: SearchOptions): number {
  storage.options = options;
  setState(true);

  const editor = window.editor;
  const selectMatch = () => {
    if (!options.refocus) {
      return;
    }

    return findNext(options.search) || findPrevious(options.search);
  };

  const query = new SearchQuery(options);
  editor.dispatch({ effects: setSearchQuery.of(query) });

  const ranges = rangesFromQuery(query);
  if (ranges !== undefined) {
    // If refocus is enabled and there's a visible range, focus on it
    if (options.refocus) {
      for (const range of ranges) {
        const rect = editor.coordsAtPos(range.from);
        if (rect !== null && rect.top >= 0 && rect.top <= editor.dom.clientHeight) {
          editor.dispatch({
            selection: EditorSelection.range(range.from, range.to),
          });

          scrollSearchMatchToVisible();
          return ranges.length;
        }
      }
    }

    selectMatch();
    return ranges.length;
  }

  selectMatch();
  return document.querySelectorAll('.cm-searchMatch').length;
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
  search.replaceAll(window.editor);
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
  return (ranges !== undefined ? ranges.length : 0) as CodeGen_Int;
}

export type { SearchOptions };

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
  options: SearchOptions | undefined;
} = {
  isEnabled: false,
  options: undefined,
};
