import { selectMatches as selectMatchesCommand } from '@codemirror/search';

export default function selectAll() {
  selectMatchesCommand(window.editor);
}
