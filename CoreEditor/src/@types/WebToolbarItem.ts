/**
 * Represents a toolbar item in native toolbars.
 */
export interface WebToolbarItem {
  id: string;
  type: 'segmented';
  title: string;
  icon: string;
  segments: WebToolbarSegment[];
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
