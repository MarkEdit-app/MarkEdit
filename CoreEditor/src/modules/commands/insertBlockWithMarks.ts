import replaceSelections from './replaceSelections';

/**
 * Generally used to insert blocks like fenced code.
 */
export default function insertBlockWithMarks(marks: string) {
  const br = window.editor.state.lineBreak;
  replaceSelections(`${marks}${br}${br}${marks}`, br.length + marks.length);
}
