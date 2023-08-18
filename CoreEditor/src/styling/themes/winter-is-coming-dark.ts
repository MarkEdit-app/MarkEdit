import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { darkBase as base } from './colors';

const colors: EditorColors = {
  accent: '#5abeb0',
  text: '#ffffff',
  comment: '#999999',
  background: '#282822',
  caret: '#219fd5',
  selection: '#103362',
  activeLine: '#0c499477',
  matchingBracket: '#22567e',
  lineNumber: '#219fd5',
  searchMatch: '#103362',
  selectionHighlight: '#1033627f',
  visibleSpace: '#3b3a32',
  diffAdded: '#3f452d',
  diffRemoved: '#552821',
  lighterBackground: '#3b3a32ee',
  bracketBorder: '#888888',
};

function theme() {
  return buildTheme(colors, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier], color: '#00bff9' },
    { tag: [tags.literal, tags.quoteMark], color: '#82aaff' },
    { tag: [tags.deleted, tags.macroName], color: base.red },
    { tag: tags.inserted, color: base.green },
    { tag: [tags.className, tags.definition(tags.typeName)], color: '#d29ffc' },
    { tag: tags.typeName, color: '#7fdbca' },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: [tags.operator, tags.operatorKeyword, tags.escape, tags.string, tags.link, tags.regexp, tags.special(tags.string)], color: '#bcf0c0' },
    { tag: [tags.function(tags.variableName), tags.propertyName, tags.function(tags.propertyName)], color: '#87aff4' },
    { tag: tags.definition(tags.propertyName), color: '#a1bde6' },
    { tag: tags.propertyName, color: '#7fdbca' },
    { tag: [tags.url, tags.tagName, tags.listMark], color: '#6dbdfa' },
    { tag: tags.emphasis, color: '#c792ea', fontStyle: 'italic' },
    { tag: tags.strong, color: '#57cdff', fontWeight: 'bold' },
    { tag: tags.linkMark, color: '#f3b8c2' },
    { tag: [tags.contentSeparator, tags.monospace], color: '#a7dbf7' },
    { tag: [tags.attributeName, tags.inlineCode, tags.codeInfo, tags.codeMark], color: '#f7ecb5' },
    { tag: tags.variableName, color: '#d6deeb' },
    { tag: [tags.atom, tags.bool, tags.number], color: '#8dec95' },
  ], 'dark');
}

export default function WinterIsComingDark(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}
