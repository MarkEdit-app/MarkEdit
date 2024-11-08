import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';

const palette = {
  gray: '#eee8d5',
  grass: '#859900',
};

const colors: EditorColors = {
  accent: '#268bd2',
  text: '#333333',
  comment: '#93a1a1',
  background: '#fdf6e3',
  caret: '#657b83',
  selection: palette.gray,
  activeLine: palette.gray,
  matchingBracket: '#d9dac1',
  lineNumber: '#9ca8a6',
  searchMatch: '#f4c09d',
  selectionHighlight: '#f4c09d80',
  visibleSpace: '#586e7580',
  lighterBackground: '#586e751a',
  bracketBorder: '#b9b9b9',
};

function theme() {
  return buildTheme(colors);
}

function highlight(palette: { grass: string }, colors: EditorColors) {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.definitionKeyword, tags.tagName], color: colors.accent },
    { tag: [tags.literal, tags.inserted], color: '#219186' },
    { tag: [tags.deleted, tags.macroName], color: '#dc322f' },
    { tag: [tags.listMark, tags.bool, tags.className, tags.definition(tags.typeName), tags.definition(tags.propertyName)], color: '#b58900' },
    { tag: [tags.variableName, tags.function(tags.propertyName)], color: colors.caret },
    { tag: [tags.link, tags.inlineCode, tags.codeMark, tags.codeInfo, tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: '#2aa198' },
    { tag: [tags.contentSeparator, tags.url, tags.propertyName, tags.linkMark], color: colors.text },
    { tag: [tags.keyword, tags.modifier, tags.operator], color: palette.grass },
    { tag: [tags.moduleKeyword, tags.labelName], color: '#cb4b16' },
    { tag: [tags.emphasis, tags.strong, tags.number, tags.atom], color: '#d33682' },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: tags.quote, color: palette.grass, fontStyle: 'italic' },
    { tag: tags.attributeName, color: colors.comment },
  ]);
}

export default function SolarizedLight(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight(palette, colors)],
  };
}

export { colors, highlight };
