import { EditorColors } from '../styling/types';
import StyleSheets from '../styling/config';

export const globalState: {
  colors?: EditorColors;
  gutterHovered: boolean;
} = {
  colors: undefined,
  gutterHovered: false,
};

export const editingState = {
  isIdle: false,
  hasSelection: false,
  compositionEnded: true,
};

export const styleSheets: StyleSheets = {};
