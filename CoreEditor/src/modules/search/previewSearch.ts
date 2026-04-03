import { getSearchQuery } from '@codemirror/search';
import rangesFromQuery from './rangesFromQuery';

import type SearchOptions from './options';
import type SearchCounterInfo from './counterInfo';

declare global {
  interface Window {
    /**
     * Bridge between CoreEditor and the MarkEdit-preview extension.
     *
     * When MarkEdit-preview is not installed, all calls are no-ops.
     */
    __markeditPreviewSPI__?: {
      performSearch(options: SearchOptions): void;
      setSearchMatchIndex(index: number): void;
      clearSearch(): void;
      searchCounterInfo(): SearchCounterInfo | undefined;
    };
  }
}

export function performPreviewSearch(options: SearchOptions) {
  _previewSPI()?.performSearch(options);
}

export function setPreviewSearchMatchIndex() {
  if (_previewSPI() === undefined) {
    return;
  }

  const state = window.editor.state;
  const cursor = state.selection.main.from;
  const ranges = rangesFromQuery(getSearchQuery(state));
  const index = ranges.findIndex(range => range.from === cursor);

  if (index >= 0) {
    _previewSPI()?.setSearchMatchIndex(index);
  }
}

export function clearPreviewSearch() {
  _previewSPI()?.clearSearch();
}

export function previewSearchCounterInfo() {
  return _previewSPI()?.searchCounterInfo();
}

function _previewSPI() {
  return window.__markeditPreviewSPI__;
}
