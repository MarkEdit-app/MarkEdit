export const isChrome = /Chrome/.test(navigator.userAgent);
export const isReleaseMode = typeof window.webkit?.messageHandlers === 'object';
