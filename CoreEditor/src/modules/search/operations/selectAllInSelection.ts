import { SearchQuery } from '@codemirror/search';
import SearchOptions from '../options';
import rangesFromQuery from '../rangesFromQuery';
import selectWithRanges from '../../selection/selectWithRanges';

export default function selectAllInSelection(options: SearchOptions) {
  const query = new SearchQuery(options);
  const state = window.editor.state;
  const ranges = state.selection.ranges;
  selectWithRanges(ranges.flatMap(range => rangesFromQuery(query, range)));
}
