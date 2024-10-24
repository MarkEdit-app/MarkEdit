import { EditorColors } from '../styling/types';
import StyleSheets from '../styling/config';

export const globalState: {
  colors?: EditorColors;
  contextMenuOpenTime: number;
  gutterHovered: boolean;
} = {
  colors: undefined,
  contextMenuOpenTime: 0,
  gutterHovered: false,
};

export const editingState = {
  isIdle: false,
  hasSelection: false,
  compositionEnded: true,
};

export const styleSheets: StyleSheets = {};
