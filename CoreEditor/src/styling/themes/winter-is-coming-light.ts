import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { lightBase as base } from './colors';

const colors: EditorColors = {
  accent: '#034c7c',
  text: '#3e3e3e',
  comment: '#357b42',
  background: '#ffffff',
  caret: '#4eb4d8',
  selection: '#cee1f0',
  activeLine: '#b0c0b033',
  matchingBracket: '#b9d9e8',
  lineNumber: '#2f86d2',
  searchMatch: '#cee1f0',
  selectionHighlight: '#cee1f0',
  visibleSpace: '#c4c5cd',
  lighterBackground: '#c4c5cd33',
  bracketBorder: '#b9b9b9',
};

function theme() {
  return buildTheme(colors);
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier], color: '#0991b6' },
    { tag: [tags.literal, tags.quoteMark], color: '#003494' },
    { tag: [tags.deleted, tags.macroName], color: base.red },
    { tag: [tags.className, tags.tagName, tags.definition(tags.typeName)], color: '#0444ac' },
    { tag: tags.typeName, color: '#dc3eb7' },
    { tag: tags.inserted, color: colors.comment },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: [tags.operator, tags.operatorKeyword, tags.escape, tags.string, tags.link, tags.regexp, tags.special(tags.string)], color: '#a44185' },
    { tag: [tags.function(tags.variableName), tags.function(tags.propertyName)], color: '#b1108e' },
    { tag: tags.definition(tags.propertyName), color: '#4a668f' },
    { tag: tags.propertyName, color: '#358a7b' },
    { tag: tags.url, color: '#924205' },
    { tag: tags.emphasis, color: '#c792ea', fontStyle: 'italic' },
    { tag: tags.strong, color: '#4e76b5', fontWeight: 'bolder' },
    { tag: tags.listMark, color: '#207bb8' },
    { tag: tags.linkMark, color: '#00ac8f' },
    { tag: [tags.contentSeparator, tags.monospace], color: '#236ebf' },
    { tag: [tags.inlineCode, tags.codeInfo, tags.codeMark], color: '#0460b1' },
    { tag: tags.attributeName, color: '#df8618' },
    { tag: tags.variableName, color: '#828282' },
    { tag: [tags.atom, tags.bool, tags.number], color: '#174781' },
  ]);
}

export default function WinterIsComingLight(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}
