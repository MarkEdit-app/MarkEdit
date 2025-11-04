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
  // Detect characters, inspired by: https://www.npmjs.com/package/detect-newline
  const lineBreaks = string.match(/(?:\r?\n|\r)/g) ?? [];
  const LFs = lineBreaks.filter(ch => ch === CHARS.LF).length;
  const CRLFs = lineBreaks.filter(ch => ch === CHARS.CRLF).length;
  const CRs = lineBreaks.filter(ch => ch === CHARS.CR).length;
  const usedMost = Math.max(LFs, CRLFs, CRs);

  // Default line endings
  if (usedMost === 0 && defaultValue !== undefined) {
    // If it's set to line feed, we prefer leave it unspecified to let CodeMirror normalize line breaks
    return defaultValue === '\n' ? undefined : defaultValue;
  }

  if (CRLFs === usedMost) {
    return CHARS.CRLF;
  } else if (CRs === usedMost) {
    return CHARS.CR;
  } else {
    // Unspecified, let CodeMirror handle it
    return undefined;
  }
}

export function normalizeLineBreaks(input: string, lineBreak: string | undefined) {
  if (lineBreak === undefined) {
    return input;
  }

  // 1. \r\n -> \n
  // 2. \r -> \n
  // 3. \n -> lineBreak if necessary
  //
  // Order matters; it may not be the fastest, but it's easy to understand.
  let output = input;
  output = output.replace(new RegExp(CHARS.CRLF, 'g'), CHARS.LF);
  output = output.replace(new RegExp(CHARS.CR, 'g'), CHARS.LF);

  if (lineBreak !== CHARS.LF) {
    output = output.replace(new RegExp(CHARS.LF, 'g'), lineBreak);
  }

  return output;
}

/**
 * If the position is at a newline, add the newline length to the position.
 */
export function takePossibleNewline(input: string, pos: number) {
  if (input.slice(pos, pos + 2) === CHARS.CRLF) {
    return pos + 2;
  }

  if (input.charAt(pos) === CHARS.LF || input.charAt(pos) === CHARS.CR) {
    return pos + 1;
  }

  return pos;
}

export type { LineEndings };
