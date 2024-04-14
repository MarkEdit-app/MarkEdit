import * as search from '@codemirror/search';

export default function selectAll() {
  search.selectMatches(window.editor);
}
