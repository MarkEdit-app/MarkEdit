import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';

const palette = {
  purple: '#c792ea',
  yellow: '#c5e478',
};

const colors: EditorColors = {
  accent: '#82b1ff',
  text: '#d6deeb',
  comment: '#637777',
  background: '#011627',
  caret: '#80a4c2',
  selection: '#1d3b53',
  activeLine: '#0003',
  matchingBracket: '#1d3443',
  lineNumber: '#4b6479',
  searchMatch: '#5f7e9779',
  selectionHighlight: '#5f7e974d',
  visibleSpace: '#26343e',
  lighterBackground: '#26343e66',
  diffAdded: '#1f3832',
  diffRemoved: '#381b25',
  bracketBorder: '#888888',
};

function theme() {
  return buildTheme(colors, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.operator, tags.operatorKeyword], color: palette.purple },
    { tag: [tags.quote, tags.quoteMark], color: '#697098', fontStyle: 'italic' },
    { tag: [tags.deleted, tags.macroName], color: '#ef535090' },
    { tag: [tags.inserted, tags.inlineCode, tags.typeName, tags.attributeName], color: palette.yellow },
    { tag: [tags.function(tags.variableName), tags.function(tags.propertyName), tags.definition(tags.propertyName)], color: '#82aaff' },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: [tags.escape, tags.string, tags.special(tags.string)], color: '#ecc48d' },
    { tag: [tags.link, tags.contentSeparator, tags.definition(tags.typeName)], color: colors.text },
    { tag: [tags.linkMark, tags.self, tags.angleBracket], color: '#7fdbca' },
    { tag: tags.listMark, color: '#d9f5dd' },
    { tag: tags.url, color: '#ff869a' },
    { tag: tags.strong, color: palette.yellow, fontWeight: 'bold' },
    { tag: tags.emphasis, color: palette.purple, fontStyle: 'italic' },
    { tag: tags.labelName, color: colors.accent },
    { tag: tags.className, color: '#ffcb8b' },
    { tag: tags.tagName, color: '#caece6' },
    { tag: tags.bool, color: '#ff5874' },
    { tag: tags.number, color: '#f78c6c' },
    { tag: tags.regexp, color: '#5ca7e4' },
  ], 'dark');
}

export default function NightOwl(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}
