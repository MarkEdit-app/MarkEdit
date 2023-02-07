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
  if (plugin !== undefined) {
    plugin.disconnect();
  }
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
