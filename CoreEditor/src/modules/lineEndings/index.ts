import { EditorState } from '@codemirror/state';
import { LineEndings } from './types';

const CHARS = {
  LF: '\n',
  CRLF: '\r\n',
  CR: '\r',
};

export function getLineEndings() {
  const editor = window.editor;
  const lineBreak = editor.state.lineBreak;

  if (lineBreak === CHARS.LF) {
    return LineEndings.LF;
  } else if (lineBreak === CHARS.CRLF) {
    return LineEndings.CRLF;
  } else if (lineBreak === CHARS.CR) {
    return LineEndings.CR;
  } else {
    return LineEndings.Unspecified;
  }
}

export function setLineEndings(lineEndings: LineEndings) {
  const extension = window.dynamics.lineEndings;
  if (extension === undefined) {
    return;
  }

  const lineBreak = (() => {
    if (lineEndings === LineEndings.CRLF) {
      return CHARS.CRLF;
    } else if (lineEndings === LineEndings.CR) {
      return CHARS.CR;
    } else {
      return CHARS.LF;
    }
  })();

  window.editor.dispatch({
    effects: extension.reconfigure(EditorState.lineSeparator.of(lineBreak)),
  });
}

export function getLineBreak(string: string, defaultValue?: string) {
  // Default line endings
  if (string.length === 0 && defaultValue !== undefined) {
    // If it's set to line feed, we prefer leave it unspecified to let CodeMirror normalize line breaks
    return defaultValue === '\n' ? undefined : defaultValue;
  }

  // Detect characters, inspired by: https://www.npmjs.com/package/detect-newline
  const lineBreaks = string.match(/(?:\r?\n|\r)/g) || [];
  const LFs = lineBreaks.filter(ch => ch === CHARS.LF).length;
  const CRLFs = lineBreaks.filter(ch => ch === CHARS.CRLF).length;
  const CRs = lineBreaks.filter(ch => ch === CHARS.CR).length;
  const usedMost = Math.max(LFs, CRLFs, CRs);

  if (CRLFs === usedMost) {
    return CHARS.CRLF;
  } else if (CRs === usedMost) {
    return CHARS.CR;
  } else {
    // Unspecified, let CodeMirror handle it
    return undefined;
  }
}

export type { LineEndings };
