import { EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';

const colors = {
  accent: '#bd93f9',
  text: '#f8f8f2',
  yellow: '#f1fa8c',
  gold: '#ffb86c',
  gray: '#6272a4',
};

function theme() {
  return buildTheme({
    text: colors.text,
    comment: colors.gray,
    background: '#282a36',
    caret: '#aeafad',
    selection: '#44475a',
    activeLine: '#00000000',
    matchingBracket: '#263032',
    lineNumber: colors.gray,
    searchMatch: '#ffffff40',
    selectedMatch: '#ffb86c7f',
    selectionHighlight: '#4244507f',
    visibleSpace: '#ffffff1a',
    lighterBackground: '#ffffff0d',
    lineBorder: '#454759',
    bracketBorder: '#888888',
  }, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.link, tags.operator, tags.operatorKeyword, tags.tagName], color: '#ff79c6' },
    { tag: [tags.quote, tags.quoteMark, tags.emphasis], color: colors.yellow, fontStyle: 'italic' },
    { tag: [tags.deleted, tags.macroName], color: '#ff5555' },
    { tag: [tags.className, tags.typeName, tags.url, tags.definition(tags.typeName), tags.listMark], color: '#8be9fd' },
    { tag: [tags.inserted, tags.attributeName, tags.inlineCode, tags.codeInfo, tags.codeMark, tags.function(tags.variableName), tags.function(tags.propertyName)], color: '#50fa7b' },
    { tag: [tags.meta, tags.comment, tags.contentSeparator], color: colors.gray, fontStyle: 'italic' },
    { tag: [tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: colors.yellow },
    { tag: tags.definition(tags.propertyName), color: colors.gold },
    { tag: tags.strong, color: colors.gold, fontWeight: 'bold' },
    { tag: tags.linkMark, color: colors.text },
  ], 'dark');
}

export default function Dracula(): EditorTheme {
  return {
    accentColor: colors.accent,
    extension: [theme(), highlight()],
  };
}
