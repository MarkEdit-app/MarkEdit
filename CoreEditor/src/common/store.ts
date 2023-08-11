import StyleSheets from '../styling/config';

export const editingState = {
  isIdle: false,
  hasSelection: false,
  compositionEnded: true,

  // Used for invisible rendering
  keystrokeTime: 0,
  invisibleSkippedTime: 0,
};

export const styleSheets: StyleSheets = {};
