import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';

const palette = {
  lightGray: '#9893a5',
  darkGray: '#797593',
};

const colors: EditorColors = {
  accent: '#56949f',
  text: '#575279',
  comment: palette.lightGray,
  background: '#faf4ed',
  caret: palette.lightGray,
  selection: '#6e6a8614',
  activeLine: '#6e6a860d',
  matchingBracket: '#0000',
  lineNumber: palette.darkGray,
  searchMatch: '#6e6a864c',
  selectionHighlight: '#6e6a8626',
  visibleSpace: palette.lightGray,
  diffAdded: '#56949f26',
  diffRemoved: '#b4637a26',
  lighterBackground: `${palette.lightGray}26`,
  bracketBorder: palette.darkGray,
};

function theme() {
  return buildTheme(colors);
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.className, tags.literal, tags.inserted, tags.tagName, tags.labelName], color: colors.accent },
    { tag: [tags.deleted, tags.macroName], color: '#b4637a' },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: [tags.link, tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: '#ea9d34' },
    { tag: [tags.url, tags.linkMark, tags.propertyName], color: colors.text },
    { tag: [tags.listMark, tags.quoteMark], color: palette.darkGray },
    { tag: [tags.keyword, tags.modifier, tags.operator, tags.operatorKeyword], color: '#286983' },
    { tag: [
      tags.contentSeparator, tags.definition(tags.typeName),
      tags.definition(tags.propertyName), tags.function(tags.propertyName),
      tags.function(tags.variableName), tags.function(tags.definition(tags.variableName)),
    ], color: '#d7827e' },
    { tag: tags.attributeName, color: '#907aa9' },
  ]);
}

export default function RosePineDawn(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}

export { colors };
