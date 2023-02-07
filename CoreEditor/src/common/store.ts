import { Compartment } from '@codemirror/state';
import StyleSheets from '../styling/config';

export const editedState = { isDirty: false };
export const selectionState = { hasSelection: false };

export const styleSheets: StyleSheets = {};
export const clickableLinks: Compartment[] = [];
