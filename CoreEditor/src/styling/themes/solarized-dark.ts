import { EditorColors, EditorTheme } from '../types';
import { buildTheme } from '../builder';
import { highlight } from './solarized-light';

const palette = {
  gray: '#073642',
  grass: '#859900',
};

const colors: EditorColors = {
  accent: '#268bd2',
  text: '#93a1a1',
  comment: '#657b83',
  background: '#002b36',
  caret: '#93a1a1',
  selection: palette.gray,
  activeLine: palette.gray,
  matchingBracket: '#083d3d',
  lineNumber: '#566c74',
  searchMatch: '#584032',
  selectionHighlight: '#005a6faa',
  visibleSpace: '#93a1a180',
  lighterBackground: '#93a1a11a',
  bracketBorder: '#888888',
};

function theme() {
  return buildTheme(colors, 'dark');
}

export default function SolarizedDark(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight(palette, colors)],
  };
}

export { colors };
