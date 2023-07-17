import { Compartment } from '@codemirror/state';
import StyleSheets from '../styling/config';

export const editingState = {
  hasSelection: false,
  compositionEnded: true,
};

export const styleSheets: StyleSheets = {};
export const clickableLinks: Compartment[] = [];
