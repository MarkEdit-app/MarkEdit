export function startCompletion() {
  // tbd
}

export function setPanelVisible(visible: boolean) {
  storage.panelVisible = visible;
}

export function isPanelVisible() {
  return storage.panelVisible;
}

const storage: {
  cancellable: ReturnType<typeof setTimeout> | undefined;
  cachedPosition: number;
  panelVisible: boolean;
} = {
  cancellable: undefined,
  cachedPosition: -1,
  panelVisible: false,
};
