import { EditorView, keymap } from '@codemirror/view';
import { EditorSelection, EditorState, Prec } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import { startCompletion as startTooltipCompletion, closeCompletion as closeTooltipCompletion, completionStatus as tooltipCompletionStatus, CompletionContext, CompletionResult, insertCompletionText, pickedCompletion, Completion, autocompletion, completionKeymap } from '@codemirror/autocomplete';
import { editingState } from '../../common/store';
import { anchorAtPos } from '../tokenizer/anchorAtPos';
import { getFootnoteLabels, getReferenceLinkLabels } from '../link';
import { getLinkAnchor, getTableOfContents } from '../toc';
import { getFileInfo, listFiles } from '../../api/files';

export const autocompleteExtensions = [
  autocompletion({
    icons: false,
    defaultKeymap: false, // See the filtered completionKeymap below
    activateOnTypingDelay: 200,
    compareCompletions: () => 0, // Don't sort options
  }),

  // In some keyboards this is used to insert the backtick, see #1171
  Prec.highest(keymap.of(completionKeymap.filter(keymap => keymap.mac !== 'Alt-`'))),
];

// https://codemirror.net/docs/ref/#state.EditorState.languageDataAt
export const standardLinkCompletion = {
  autocomplete: async(context: CompletionContext): Promise<CompletionResult | null> => {
    const match = context.matchBefore(/[#./^].*/);
    if (match === null) {
      return null;
    }

    const nodeName = linkNodeName(context.state, context.pos);
    const insideLink = nodeName !== undefined;
    const hasPartialLink = context.matchBefore(/\[.*\]\(.*/) !== null;
    if (!insideLink && !hasPartialLink) {
      return null;
    }

    const matchText = match.text;
    const partialMode = !insideLink && hasPartialLink;
    const boundaryPos = partialMode ? undefined : bracketBoundary(context);
    const closeBracket = partialMode ? ')' : '';

    const applyCompletion = (editor: EditorView, completion: Completion, from: number, to: number, text: string) => {
      editor.dispatch({
        ...insertCompletionText(editor.state, text, from, to),
        annotations: pickedCompletion.of(completion),
      });

      if (closeBracket.length > 0) {
        editor.dispatch({
          selection: EditorSelection.cursor(from + text.length - closeBracket.length),
        });
      }
    };

    // Internal anchors like [title](#heading)
    if (matchText.startsWith('#') && nodeName !== 'Image') {
      return {
        from: match.from,
        to: boundaryPos,
        options: getTableOfContents().map(info => {
          const label = '#' + getLinkAnchor(info.title);
          return {
            type: 'text',
            label,
            apply: (editor, completion, from, to) => applyCompletion(editor, completion, from, to, label + closeBracket),
          };
        }),
        validFor: /^#[\p{L}\p{N}_]*$/u,
      };
    }

    // Relative file paths like [file](/docs.md)
    if (matchText.startsWith('.') || matchText.startsWith('/')) {
      const directory = matchText.includes('/') ? matchText.substring(0, matchText.lastIndexOf('/')) : matchText;
      const parentPath = (await getFileInfo())?.parentPath ?? '';
      const filenames = (await listFiles(joinPaths(parentPath, directory)))?.filter(name => name !== '.DS_Store');

      return {
        from: match.from,
        to: boundaryPos,
        options: (filenames ?? []).map(filename => {
          const label = joinPaths(directory, filename);
          return {
            type: 'text',
            label,
            apply: async(editor, completion, from, to) => {
              const filePath = joinPaths(parentPath, label);
              const isDirectory = (await getFileInfo(filePath))?.isDirectory === true;
              const escapedText = label.replace(/ /g, '%20');
              const textToApply = (isDirectory ? joinPaths(escapedText, '') : escapedText) + closeBracket;
              applyCompletion(editor, completion, from, to, textToApply);

              if (isDirectory) {
                setTimeout(() => startTooltipCompletion(editor), 200);
              }
            },
          };
        }),
      };
    }

    // Footnotes like [^footnote]
    if (matchText.startsWith('^')) {
      return {
        from: match.from,
        options: getFootnoteLabels(context.state).map(label => ({ type: 'text', label })),
      };
    }

    return null;
  },
};

// https://codemirror.net/docs/ref/#state.EditorState.languageDataAt
export const referenceLinkCompletion = {
  autocomplete: (context: CompletionContext): CompletionResult | null => {
    const regex = /(\[.+\]\[).*/;
    const match = context.matchBefore(regex);
    if (match === null || context.tokenBefore(['Link']) === null) {
      return null;
    }

    const prefix = match.text.match(regex);
    const offset = prefix === null ? 0 : prefix[1].length;
    return {
      from: match.from + offset,
      to: bracketBoundary(context),
      options: getReferenceLinkLabels(context.state).map(label => ({ type: 'text', label })),
    };
  },
};

/**
 * The start of a multi-stage completion process:
 *
 *  1. This method is called automatically if "suggestWhileTyping" is enabled, or manually like pressing cmd-esc on macOS
 *  2. This method calls client with an anchor for tokenization, and optionally the whole document
 *  3. Client determines the "prefix" to complete, and its range
 *  4. Client calls CoreEditor to request the rectangle and shows the panel
 *  5. CoreEditor intercepts navigation keys and calls client to update the panel
 *  6. Client calls CoreEditor to commit the selection
 *
 * Note that, "afterDelay" is used typically for "suggest while typing" scenario.
 */
export function startCompletion({ afterDelay }: { afterDelay: number }) {
  if (storage.cancellable !== undefined) {
    clearTimeout(storage.cancellable);
  }

  // Don't trigger completion for every keystroke,
  // instead we delay the request cancel previously scheduled ones.
  storage.cancellable = setTimeout(() => {
    // We don't want to trigger completion when composition is still ongoing,
    // marked text in input methods like Pinyin is not meaningful until composition is ended.
    if (!editingState.compositionEnded) {
      return;
    }

    const editor = window.editor;
    const state = editor.state;
    const pos = state.selection.main.to;
    const anchor = anchorAtPos(pos);

    // Inside a link, try anchor completion
    if (linkNodeName(state, pos) !== undefined) {
      return toggleTooltipCompletion();
    }

    // Defensive fix for string slicing issue,
    // the pos at the end of a string is valid and it's the most common case for word completion.
    if (anchor.pos < 0 && anchor.pos > anchor.text.length) {
      return console.error(`Invalid anchor at pos: ${pos}`);
    }

    const fullText = (() => {
      const position = editor.coordsAtPos(pos)?.top ?? 0;
      const usesCache = Math.abs(position - storage.cachedPosition) < 5;
      storage.cachedPosition = position;

      // If y-axis isn't changed noticeably, it means that we are keep working on the same line.
      // In that case, we skip sending full text for tokenization to improve the performance.
      //
      // This is not sound, and we don't want a sound but super complicated algorithm.
      if (usesCache) {
        return undefined;
      } else {
        return state.doc.toString();
      }
    })();

    window.nativeModules.completion.requestCompletions({ anchor, fullText });
  }, afterDelay);
}

export function setPanelVisible(visible: boolean) {
  storage.panelVisible = visible;
}

export function isPanelVisible() {
  return storage.panelVisible;
}

export function hasTooltipCompletion() {
  return tooltipCompletionStatus(window.editor.state) === 'active';
}

export function toggleTooltipCompletion() {
  if (hasTooltipCompletion()) {
    closeTooltipCompletion(window.editor);
  } else {
    startTooltipCompletion(window.editor);
  }
}

export function invalidateCache() {
  storage.cachedPosition = -1;
}

export function acceptInlinePrediction(prediction: string) {
  const editor = window.editor;
  const anchor = editor.state.selection.main.to;
  const line = editor.state.doc.lineAt(anchor);

  // Generate a slice for string comparison.
  //
  // For example, we are typing "Hello, ple" and the prediction is "please",
  // the slice would be "o, ple".
  const slice = editor.state.sliceDoc(Math.max(line.from, anchor - prediction.length), anchor);

  // Figure out the first offset that makes the substring a prefix of the prediction.
  //
  // For the "o, ple" and "please" example, the offset will be 3,
  // so that we are replacing "ple" with "please" to accept the inline prediction.
  for (let offset = 0; offset < slice.length; ++offset) {
    if (prediction.startsWith(slice.substring(offset))) {
      const from = anchor - slice.length + offset;
      return editor.dispatch({
        changes: { from, to: anchor, insert: prediction },
        selection: EditorSelection.cursor(from + prediction.length),
      });
    }
  }
}

function linkNodeName(state: EditorState, pos: number) {
  const nodeName = syntaxTree(state).resolveInner(pos).name;
  if (['Link', 'Image', 'URL'].includes(nodeName)) {
    return nodeName;
  }

  return undefined;
}

function joinPaths(path1: string, path2: string) {
  if (path1.endsWith('/')) {
    return path1 + path2;
  }

  return path1 + '/' + path2;
}

function bracketBoundary(context: CompletionContext) {
  let offset = context.state.selection.main.to;
  const lineEnd = context.state.doc.lineAt(offset).to;

  while (offset < lineEnd) {
    const ch = context.state.sliceDoc(offset, offset + 1);
    if (ch === ')' || ch === ']') {
      return offset;
    }

    ++offset;
  }

  return undefined;
}

const storage: {
  cancellable: ReturnType<typeof setTimeout> | undefined;
  cachedPosition: number;
  panelVisible: boolean;
} = {
  cancellable: undefined,
  cachedPosition: -1,
  panelVisible: false,
};
