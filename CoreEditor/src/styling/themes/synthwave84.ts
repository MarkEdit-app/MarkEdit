import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { shadowableTextColor } from '../helper';
import { darkBase as base } from './colors';

const palette = {
  orange: '#f97e72',
  yellow: '#f4eee4',
  green: '#72f1b8',
  blue: '#2fe2f9',
};

const colors: EditorColors = {
  accent: 'color: #f92aad; text-shadow: 0 0 2px #100c0f, 0 0 5px #dc078e33, 0 0 10px #fff3',
  text: '#f0eff1',
  comment: '#848bbd',
  background: '#252335',
  caret: palette.orange,
  selection: '#ffffff20',
  activeLine: '#00000000',
  matchingBracket: '#2b2640',
  lineNumber: '#ffffff73',
  searchMatch: '#d18616bb',
  selectionHighlight: '#3b3450',
  visibleSpace: '#444351',
  lighterBackground: '#44435166',
  lineBorder: '#7059ab66',
  bracketBorder: '#495495',
};

const glows = {
  yellow: shadowableTextColor(`color: ${palette.yellow}; text-shadow: 0 0 2px #393a33, 0 0 8px #f39f0575, 0 0 2px #f39f0575`),
  green: shadowableTextColor(`color: ${palette.green}; text-shadow: 0 0 2px #100c0f, 0 0 10px #257c5575, 0 0 35px #21272475`),
  blue: shadowableTextColor('color: #fdfdfd; text-shadow: 0 0 2px #001716, 0 0 3px #03edf975, 0 0 5px #03edf975, 0 0 8px #03edf975'),
  red: shadowableTextColor('color: #fff5f6; text-shadow: 0 0 2px #000, 0 0 10px #fc1f2c75, 0 0 5px #fc1f2c75, 0 0 25px #fc1f2c75'),
};

function theme() {
  return buildTheme(colors, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.link, tags.operator, tags.operatorKeyword, tags.attributeName], ...glows.yellow },
    { tag: [tags.deleted, tags.macroName], color: base.red },
    { tag: [tags.inserted], color: base.green },
    { tag: [tags.className, tags.typeName, tags.definition(tags.typeName), tags.self], ...glows.red },
    { tag: [tags.function(tags.variableName), tags.function(tags.propertyName), tags.angleBracket, tags.listMark], ...glows.blue },
    { tag: [tags.meta, tags.comment], color: colors.comment, fontStyle: 'italic' },
    { tag: [tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: '#ff8b38' },
    { tag: [tags.name, tags.character, tags.definition(tags.name), tags.definition(tags.propertyName)], ...shadowableTextColor(colors.accent) },
    { tag: tags.contentSeparator, color: colors.comment },
    { tag: tags.strong, color: palette.blue, fontWeight: 'bold' },
    { tag: tags.emphasis, color: palette.blue, fontStyle: 'italic' },
    { tag: tags.linkMark, color: colors.text },
    { tag: [tags.inlineCode, tags.tagName, tags.url], ...glows.green },
    { tag: [tags.quote, tags.quoteMark], ...glows.green, fontStyle: 'italic' },
    { tag: [tags.labelName, tags.null, tags.number, tags.bool], color: palette.orange },
  ], 'dark');
}

export default function SynthWave84(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}
