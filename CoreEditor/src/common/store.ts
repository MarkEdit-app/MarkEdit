import { EditorColors } from '../styling/types';
import StyleSheets from '../styling/config';

export const globalState: {
  colors?: EditorColors;
  contextMenuOpenTime: number;
  gutterHovered: boolean;
  hasModalSheet: boolean;
} = {
  colors: undefined,
  contextMenuOpenTime: 0,
  gutterHovered: false,
  hasModalSheet: false,
};

export const editingState = {
  hasSelection: false,
  compositionEnded: true,
};

export const styleSheets: StyleSheets = {};
