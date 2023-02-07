import { WidgetType } from '@codemirror/view';

/**
 * Extend WidgetType with a pos to indicate where to draw.
 */
export abstract class WidgetView extends WidgetType {
  pos: number;
}
