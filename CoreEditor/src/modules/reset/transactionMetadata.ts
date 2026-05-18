import { Annotation } from '@codemirror/state';

export const resetContentReloadAnnotation = Annotation.define<boolean>();
export const resetCursorPlacementAnnotation = Annotation.define<boolean>();
export const resetScrollRestoreMeasureKey = 'MarkEdit.resetScrollRestore';
export const resetCursorPlacementMeasureKey = 'MarkEdit.resetCursorPlacement';
