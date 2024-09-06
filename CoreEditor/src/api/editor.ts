import { EditorView } from '@codemirror/view';
import { EditorSelection, EditorState, Text } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import { TextEditable, TextRange } from 'markedit-api';
import { redo, undo } from '../@vendor/commands/history';

/**
 * TextEditable implementation to provide convenient text editing interfaces.
 */
export class TextEditor implements TextEditable {
  setView(view: EditorView) {
    this.view = view;
  }

  getText(range?: TextRange): string {
    if (range === undefined) {
      return this.doc.toString();
    }

    const { from, to } = range;
    return this.doc.sliceString(from, to);
  }

  setText(text: string, range?: TextRange): void {
    const from = range === undefined ? 0 : range.from;
    const to = range === undefined ? this.doc.length : range.to;
    this.view.dispatch({
      changes: { from, to, insert: text },
    });
  }

  getSelections(): TextRange[] {
    return this.state.selection.ranges.map(({ from, to }) => ({ from, to }));
  }

  setSelections(ranges: TextRange[]): void {
    const selections = ranges.map(({ from, to }) => EditorSelection.range(from, to));
    this.view.dispatch({
      selection: EditorSelection.create(selections),
    });
  }

  getLineNumber(position: number): number {
    return this.doc.lineAt(position).number - 1;
  }

  getLineRange(row: number): TextRange {
    const { from, to } = this.doc.line(row + 1);
    return { from, to };
  }

  getLineCount(): number {
    return this.doc.lines;
  }

  getLineBreak(): string {
    return this.state.lineBreak;
  }

  getNodeName(position: number): string {
    return syntaxTree(this.state).resolve(position).name;
  }

  undo(): void {
    undo(this.view);
  }

  redo(): void {
    redo(this.view);
  }

  // MARK: - Private

  private view = window.editor;

  private get state(): EditorState {
    return this.view.state;
  }

  private get doc(): Text {
    return this.state.doc;
  }
}
