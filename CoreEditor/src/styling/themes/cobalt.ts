import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { darkBase as base } from './colors';

const palette = {
  accent: '#ffc600',
  cyan: '#9effff',
};

const colors: EditorColors = {
  accent: palette.accent,
  text: '#e1efff',
  comment: '#0088ff',
  background: '#193549',
  caret: palette.accent,
  selection: '#0050A4',
  activeLine: '#1F4662',
  matchingBracket: '#0e3a59',
  lineNumber: '#aaaaaa',
  searchMatch: '#cad40f66',
  selectionHighlight: '#0050a480',
  visibleSpace: '#ffffff52',
  lighterBackground: '#ffffff1a',
  diffAdded: '#34504d',
  diffRemoved: '#4d3341',
  lineBorder: '#234e6d',
  bracketBorder: '#8b8145',
};

function theme() {
  return buildTheme(colors, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.operator, tags.operatorKeyword], color: '#ff9d00' },
    { tag: [tags.quote, tags.emphasis], color: palette.cyan, fontStyle: 'italic' },
    { tag: [tags.deleted, tags.macroName], color: base.red },
    { tag: [tags.link, tags.escape, tags.string, tags.inserted, tags.regexp, tags.listMark, tags.special(tags.string)], color: '#a5ff90' },
    { tag: [tags.url, tags.tagName, tags.codeInfo], color: palette.cyan },
    { tag: [tags.className, tags.attributeName, tags.definition(tags.typeName), tags.function(tags.variableName)], color: colors.accent },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: [tags.linkMark, tags.quoteMark], color: colors.text },
    { tag: [tags.contentSeparator, tags.definition(tags.variableName), tags.function(tags.propertyName)], color: colors.accent },
    { tag: [tags.atom, tags.bool, tags.number], color: '#ff628c' },
    { tag: tags.typeName, color: '#80ffbb' },
    { tag: tags.strong, color: palette.cyan, fontWeight: 'bolder' },
    { tag: tags.self, color: '#fb94ff' },
  ], 'dark');
}

export default function Cobalt(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}
