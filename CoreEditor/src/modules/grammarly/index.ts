import * as Grammarly from '@grammarly/editor-sdk';

let grammarly: Grammarly.EditorSDK | undefined = undefined;
let plugin: Grammarly.GrammarlyEditorPluginElement | undefined = undefined;

/**
 * Connect to a Grammarly instance: https://developer.grammarly.com/.
 */
export function connect(clientID: string, redirectURI: string) {
  const element = document.querySelector('div[contenteditable=true]');
  if (!(element instanceof HTMLElement)) {
    console.error('Failed to retrieve contentEditable from the DOM tree');
    return;
  }

  const setUp = (sdk: Grammarly.EditorSDK) => {
    plugin = sdk.addPlugin(element, {
      activation: 'immediate',
      oauthRedirectUri: redirectURI,
    });

    // Don't let Grammarly steal the focus, typing is more important
    window.editor.focus();
    grammarly = sdk;
    storage.isConnected = true;
  };

  if (grammarly === undefined) {
    (async() => {
      try {
        setUp(await Grammarly.init(clientID));
      } catch (error) {
        console.error(error);
      }
    })();
  } else {
    // Unfornately, plugin.connect() won't bring the plugin back,
    // we have to call addPlugin again
    setUp(grammarly);
  }
}

export function disconnect() {
  plugin?.disconnect();
  storage.isConnected = false;
}

/**
 * Native code redirects openURL to finish OAuth.
 *
 * @param url URL that contains auth information
 */
export function completeOAuth(url: string) {
  if (grammarly !== undefined) {
    grammarly.handleOAuthCallback(url);
  } else {
    console.error('Grammarly is not initialized yet');
  }
}

/**
 * To make sure the suggestion dialog is always (kind of) visible.
 */
export function centerActiveDialog() {
  setTimeout(() => {
    const shadowRoot = (document.querySelector('grammarly-editor-plugin') as HTMLElement | null)?.shadowRoot;
    const activeDialog = shadowRoot?.querySelector("div[role='dialog']") as HTMLElement | undefined | null;
    if (activeDialog === null || activeDialog === undefined) {
      return;
    }

    const windowHeight = window.innerHeight;
    const dialogHeight = activeDialog.clientHeight;
    const padding = 20;

    const minY = activeDialog.offsetTop;
    const maxY = minY + dialogHeight;

    // In a good shape, we only center the dialog when it's nearly cut
    if ((minY >= padding) && (maxY <= windowHeight - padding)) {
      return;
    }

    const centerTop = (dialogHeight - windowHeight) * 0.5;
    const scrollTop = window.editor.scrollDOM.scrollTop;

    window.editor.scrollDOM.scrollTo({
      top: minY + centerTop + scrollTop,
      behavior: 'smooth',
    });
  }, 500);
}

/**
 * Learn more: https://github.com/grammarly/grammarly-for-developers/discussions/569
 */
export function trottleMutations() {
  // eslint-disable-next-line no-global-assign
  MutationObserver = new Proxy(MutationObserver, {
    construct(target, args) {
      return new target(mutations => {
        const callback = args[0];
        if (typeof callback !== 'function') {
          return;
        }

        // When scroll fast, Grammarly can generate thousands of mutations
        if (storage.isIdle && (callback.toString() as string).includes('updateText')) {
          return;
        }

        callback(mutations);
      });
    },
  });
}

/**
 * Learn more: https://github.com/grammarly/grammarly-for-developers/discussions/569
 */
export function setIdle(isIdle: boolean) {
  storage.isIdle = storage.isConnected && isIdle;
  if (storage.mutateTimer !== undefined) {
    clearTimeout(storage.mutateTimer);
  }

  if (storage.isIdle || !storage.isConnected) {
    return;
  }

  // This triggers a MutationObserver change, which leads to Grammarly to re-check
  storage.mutateTimer = setTimeout(() => {
    const element = window.editor.contentDOM;
    element.setAttribute('x-grammarly-date', `${Date.now()}`);
  }, 900);
}

const storage: {
  isConnected: boolean;
  isIdle: boolean;
  mutateTimer: ReturnType<typeof setTimeout> | undefined;
} = {
  isConnected: false,
  isIdle: true,
  mutateTimer: undefined,
};
