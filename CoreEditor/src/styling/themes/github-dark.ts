import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { darkBase as base } from './colors';

const colors: EditorColors = {
  accent: '#79c0ff',
  text: '#c9d1d9',
  comment: '#8b949e',
  background: '#0d1116',
  caret: '#58a6ff',
  selection: '#264f78',
  activeLine: '#6e76811a',
  matchingBracket: '#24432e',
  lineNumber: '#6e7681',
  searchMatch: '#f2cc607f',
  selectionHighlight: '#3fb95021',
  visibleSpace: '#484f58',
  lighterBackground: '#484f5866',
  bracketBorder: '#358a43',
};

function theme() {
  return buildTheme(colors, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.operator, tags.operatorKeyword], color: '#ff7b72' },
    { tag: [tags.literal, tags.inserted, tags.tagName], color: base.green },
    { tag: [tags.deleted, tags.macroName], color: base.red },
    { tag: [tags.className, tags.definition(tags.propertyName), tags.definition(tags.typeName), tags.listMark], color: '#ffa657' },
    { tag: [tags.function(tags.variableName), tags.function(tags.propertyName)], color: '#d2a8ff' },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: [tags.link, tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: '#a5d6ff' },
    { tag: [tags.url, tags.linkMark, tags.propertyName], color: colors.text },
    { tag: [tags.quote, tags.quoteMark], color: base.green, fontStyle: 'italic' },
  ], 'dark');
}

export default function GitHubDark(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}

export { colors };
