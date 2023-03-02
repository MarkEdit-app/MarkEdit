import { Compartment } from '@codemirror/state';
import StyleSheets from '../styling/config';

export const editingState = {
  isDirty: false,
  hasSelection: false,
  compositionEnded: true,
};

export const styleSheets: StyleSheets = {};
export const clickableLinks: Compartment[] = [];
