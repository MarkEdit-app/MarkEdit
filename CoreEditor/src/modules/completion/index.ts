import { EditorSelection, EditorState } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import { startCompletion as startTooltipCompletion, closeCompletion as closeTooltipCompletion, completionStatus as tooltipCompletionStatus, CompletionContext, CompletionResult } from '@codemirror/autocomplete';
import { editingState } from '../../common/store';
import { anchorAtPos } from '../tokenizer/anchorAtPos';
import { getLinkAnchor, getTableOfContents } from '../toc';
import { getFileInfo, listFiles } from '../../api/files';

// https://codemirror.net/docs/ref/#state.EditorState.languageDataAt
export const customCompletionData = {
  autocomplete: async(context: CompletionContext): Promise<CompletionResult | null> => {
    const match = context.matchBefore(/[#./].*/);
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
    const closeBracket = (!insideLink && hasPartialLink) ? ')' : '';

    // Internal anchors like [title](#heading)
    if (matchText.startsWith('#') && nodeName !== 'Image') {
      return {
        from: match.from,
        options: getTableOfContents().map(info => {
          const label = '#' + getLinkAnchor(info.title);
          return {
            type: 'text',
            label,
            apply: label + closeBracket,
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
        options: (filenames ?? []).map(filename => {
          const label = joinPaths(directory, filename);
          return {
            type: 'text',
            label,
            apply: label.replace(/ /g, '%20') + closeBracket,
          };
        }),
      };
    }

    return null;
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
  if (nodeName === 'Link' || nodeName === 'Image') {
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

const storage: {
  cancellable: ReturnType<typeof setTimeout> | undefined;
  cachedPosition: number;
  panelVisible: boolean;
} = {
  cancellable: undefined,
  cachedPosition: -1,
  panelVisible: false,
};
