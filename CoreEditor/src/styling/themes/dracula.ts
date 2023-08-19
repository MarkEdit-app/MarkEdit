import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';

const palette = {
  yellow: '#f1fa8c',
  gold: '#ffb86c',
  gray: '#6272a4',
};

const colors: EditorColors = {
  accent: '#bd93f9',
  text: '#f8f8f2',
  comment: palette.gray,
  background: '#282a36',
  caret: '#aeafad',
  selection: '#44475a',
  activeLine: '#00000000',
  matchingBracket: '#263032',
  lineNumber: palette.gray,
  searchMatch: '#ffffff40',
  selectionHighlight: '#4244507f',
  visibleSpace: '#ffffff1a',
  lighterBackground: '#ffffff0d',
  diffAdded: '#3e473d',
  diffRemoved: '#552a31',
  lineBorder: '#454759',
  bracketBorder: '#888888',
};

function theme() {
  return buildTheme(colors, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.link, tags.operator, tags.operatorKeyword, tags.tagName], color: '#ff79c6' },
    { tag: [tags.quote, tags.quoteMark, tags.emphasis], color: palette.yellow, fontStyle: 'italic' },
    { tag: [tags.deleted, tags.macroName], color: '#ff5555' },
    { tag: [tags.className, tags.typeName, tags.url, tags.definition(tags.typeName), tags.listMark], color: '#8be9fd' },
    { tag: [tags.inserted, tags.attributeName, tags.inlineCode, tags.codeInfo, tags.codeMark, tags.function(tags.variableName), tags.function(tags.propertyName)], color: '#50fa7b' },
    { tag: [tags.meta, tags.comment], color: palette.gray, fontStyle: 'italic' },
    { tag: [tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: palette.yellow },
    { tag: tags.contentSeparator, color: palette.gray },
    { tag: tags.definition(tags.propertyName), color: palette.gold },
    { tag: tags.strong, color: palette.gold, fontWeight: 'bold' },
    { tag: tags.linkMark, color: colors.text },
  ], 'dark');
}

export default function Dracula(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}
