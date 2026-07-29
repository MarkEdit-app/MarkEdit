import { tryGetEditor } from './utils';
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
  wasScrolledToBottom: false,
  compositionEnded: true,
  compositionPosition: undefined as number | undefined,
};

/**
 * Whether a composition is in progress.
 *
 * CodeMirror is also consulted, it observes 'compositionupdate' and sees compositions we miss.
 */
export function isComposing() {
  return !editingState.compositionEnded || tryGetEditor()?.compositionStarted === true;
}

export const styleSheets: StyleSheets = {};
