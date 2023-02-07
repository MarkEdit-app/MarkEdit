import { EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { darkBase as base } from './colors';

const colors = {
  accent: '#ffc600',
  text: '#e1efff',
  cyan: '#9effff',
};

function theme() {
  return buildTheme({
    text: colors.text,
    background: '#193549',
    caret: colors.accent,
    selection: '#0050A4',
    activeLine: '#1F4662',
    matchingBracket: '#0e3a59',
    lineNumber: '#aaaaaa',
    searchMatch: '#cad40f66',
    selectedMatch: '#ff720066',
    selectionHighlight: '#0050a440',
    visibleSpace: '#ffffff52',
    lighterBackground: '#ffffff1a',
    lineBorder: '#234e6d',
    bracketBorder: '#8b8145',
  }, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.operator, tags.operatorKeyword], color: '#ff9d00' },
    { tag: [tags.quote, tags.emphasis], color: colors.cyan, fontStyle: 'italic' },
    { tag: [tags.deleted, tags.macroName], color: base.red },
    { tag: [tags.link, tags.escape, tags.string, tags.inserted, tags.regexp, tags.listMark, tags.special(tags.string)], color: '#a5ff90' },
    { tag: [tags.url, tags.tagName, tags.codeInfo], color: colors.cyan },
    { tag: [tags.className, tags.attributeName, tags.definition(tags.typeName), tags.function(tags.variableName)], color: colors.accent },
    { tag: tags.typeName, color: '#80ffbb' },
    { tag: [tags.meta, tags.comment], color: '#0088ff' },
    { tag: tags.strong, color: colors.cyan, fontWeight: 'bold' },
    { tag: [tags.linkMark, tags.quoteMark], color: colors.text },
    { tag: [tags.contentSeparator, tags.definition(tags.variableName), tags.function(tags.propertyName)], color: colors.accent },
    { tag: [tags.atom, tags.bool, tags.number], color: '#ff628c' },
    { tag: tags.self, color: '#fb94ff' },
  ], 'dark');
}

export default function Cobalt(): EditorTheme {
  return {
    accentColor: colors.accent,
    extension: [theme(), highlight()],
  };
}
