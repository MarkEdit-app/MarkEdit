import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { darkBase as base } from './colors';

const colors: EditorColors = {
  accent: '#79c0ff',
  text: '#e6edf3',
  comment: '#8b949e',
  background: '#0d1117',
  caret: '#2f81f7',
  selection: '#264f78',
  activeLine: '#6e76811a',
  matchingBracket: '#3fb95040',
  lineNumber: '#6e7681',
  searchMatch: '#f2cc6080',
  selectionHighlight: '#3fb95040',
  visibleSpace: '#484f58',
  lighterBackground: '#6e76811a',
  bracketBorder: '#3fb95099',
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
    { tag: [tags.className, tags.definition(tags.propertyName), tags.definition(tags.typeName), tags.listMark, tags.codeInfo], color: '#ffa657' },
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
