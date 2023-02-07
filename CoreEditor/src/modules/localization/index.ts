import { EditorState } from '@codemirror/state';

// https://codemirror.net/examples/translate/
export function localizePhrases() {
  const strings = window.config.localizable;
  return EditorState.phrases.of({
    // "key": "value" ?? "fallback"
    'Control character': strings?.controlCharacter ?? 'Control Character',
    'Folded lines': strings?.foldedLines ?? 'Folded Lines',
    'Unfolded lines': strings?.unfoldedLines ?? 'Unfolded Lines',
    'folded code': strings?.foldedCode ?? 'Folded Code',
    'unfold': strings?.unfold ?? 'Unfold',
    'Fold line': strings?.foldLine ?? 'Fold Line',
    'Unfold line': strings?.unfoldLine ?? 'Unfold Line',
  });
}
