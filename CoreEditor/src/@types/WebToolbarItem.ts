import { WebMenuItem } from './WebMenuItem';

/**
 * Represents a toolbar item in native toolbars.
 */
export interface WebToolbarItem {
  id: string;
  type: 'button' | 'menu' | 'segmented' | 'group';
  title: string;
  icon: string;
  initialPlacement: 'toolbar' | 'customization';
  actionID?: string;
  stateGetterID?: string;
  children?: WebMenuItem[];
  segments?: WebToolbarSegment[];
}

/**
 * Represents a segment within a toolbar item.
 */
export interface WebToolbarSegment {
  title: string;
  icon: string;
  actionID: string;
  stateGetterID: string;
}

/**
 * State snapshot for a toolbar control or menu entry.
 */
export interface WebToolbarItemState {
  isEnabled?: boolean;
  isSelected?: boolean;
  title?: string;
  icon?: string;
}
