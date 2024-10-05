export const isChrome = /Chrome/.test(navigator.userAgent);
export const isReleaseMode = typeof window.webkit?.messageHandlers === 'object';

export function getModuleID() {
  return typeof MARKEDIT_MODULE_ID === 'string' ? MARKEDIT_MODULE_ID : 'MARKEDIT_DEBUG_MODULE';
}
