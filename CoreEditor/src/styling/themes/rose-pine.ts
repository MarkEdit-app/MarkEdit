import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';

const palette = {
  lightGray: '#6e6a86',
  darkGray: '#908caa',
};

const colors: EditorColors = {
  accent: '#9ccfd8',
  text: '#e0def4',
  comment: palette.lightGray,
  background: '#191724',
  caret: palette.lightGray,
  selection: '#6e6a8633',
  activeLine: '#6e6a861a',
  matchingBracket: '#0000',
  lineNumber: palette.darkGray,
  searchMatch: '#6e6a8666',
  selectionHighlight: '#6e6a8666',
  visibleSpace: palette.lightGray,
  lighterBackground: `${palette.lightGray}66`,
  diffAdded: '#9ccfd826',
  diffRemoved: '#eb6f9226',
  bracketBorder: palette.darkGray,
};

function theme() {
  return buildTheme(colors, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.className, tags.literal, tags.inserted, tags.tagName, tags.labelName], color: colors.accent },
    { tag: [tags.deleted, tags.macroName], color: '#eb6f92' },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: [tags.link, tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: '#f6c177' },
    { tag: [tags.url, tags.linkMark, tags.propertyName], color: colors.text },
    { tag: [tags.listMark, tags.quoteMark], color: palette.darkGray },
    { tag: [tags.keyword, tags.modifier, tags.operator, tags.operatorKeyword], color: '#31748f' },
    { tag: [
      tags.contentSeparator, tags.definition(tags.typeName),
      tags.definition(tags.propertyName), tags.function(tags.propertyName),
      tags.function(tags.variableName), tags.function(tags.definition(tags.variableName)),
    ], color: '#ebbcba' },
    { tag: tags.attributeName, color: '#c4a7e7' },
  ], 'dark');
}

export default function RosePine(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}

export { colors };
