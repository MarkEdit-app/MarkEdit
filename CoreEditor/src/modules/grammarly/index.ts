import * as Grammarly from '@grammarly/editor-sdk';
import { highlightSelectionMatches } from '@codemirror/search';
import { InvisiblesBehavior } from '../../config';
import { setInvisiblesBehavior } from '../config';

/**
 * Connect to a Grammarly instance: https://developer.grammarly.com/.
 */
export async function connect(clientID: string, redirectURI: string) {
  try {
    const editor = window.editor;
    const selection = editor.state.selection;
    if (grammarly.sdk === undefined) {
      grammarly.sdk = await Grammarly.init(clientID);
    }

    // Unfornately, plugin.connect() won't bring the plugin back,
    // we must call addPlugin every time we re-enable Grammarly.
    grammarly.plugin = grammarly.sdk.addPlugin(window.editor.contentDOM, {
      activation: 'immediate',
      oauthRedirectUri: redirectURI,
    });

    // Here we apply two workarounds:
    //  1. Toggle InvisiblesBehavior.selection/never because it stops Grammarly from working
    //  2. Toggle selectionHighlight extension for the same reason
    //
    // The reason here is that these extensions create temporary <span> elements,
    // which break text selections when accepting Grammarly suggestions.
    grammarly.plugin.addEventListener('suggestion-card-open', () => {
      storage.invisibleBehavior = window.config.invisiblesBehavior;
      if (storage.invisibleBehavior === InvisiblesBehavior.selection) {
        setInvisiblesBehavior(InvisiblesBehavior.never);
      }

      editor.dispatch({
        effects: window.dynamics.selectionHighlight?.reconfigure([]),
      });
    });

    grammarly.plugin.addEventListener('suggestion-card-close', () => {
      setTimeout(() => {
        if (storage.invisibleBehavior === InvisiblesBehavior.selection) {
          setInvisiblesBehavior(InvisiblesBehavior.selection);
        }

        storage.invisibleBehavior = undefined;
        editor.dispatch({
          effects: window.dynamics.selectionHighlight?.reconfigure(highlightSelectionMatches()),
        });
      }, 100);
    });

    // Don't let Grammarly steal the focus, typing is more important
    editor.focus();
    setTimeout(() => editor.dispatch({ selection }), 5);
    storage.isConnected = true;
  } catch (error) {
    console.error(error);
  }
}

export function disconnect() {
  grammarly.plugin?.disconnect();
  storage.isConnected = false;
}

/**
 * Native code redirects openURL to finish OAuth.
 *
 * @param url URL that contains auth information
 */
export function completeOAuth(url: string) {
  if (grammarly.sdk !== undefined) {
    grammarly.sdk.handleOAuthCallback(url);
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

        // When scroll fast, Grammarly's update functions can generate thousands of mutations
        if (storage.isIdle) {
          const source = callback.toString() as string;
          if (source.includes('updateText') || (source.includes('isConnected') && source.includes('"IFRAME"'))) {
            return;
          }
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
    const contentDOM = window.editor.contentDOM;
    contentDOM.setAttribute('x-grammarly-date', `${Date.now()}`);
  }, 900);
}

export function isConnected() {
  return storage.isConnected;
}

const grammarly: {
  sdk: Grammarly.EditorSDK | undefined;
  plugin: Grammarly.GrammarlyEditorPluginElement | undefined;
} = {
  sdk: undefined,
  plugin: undefined,
};

const storage: {
  isConnected: boolean;
  isIdle: boolean;
  mutateTimer: ReturnType<typeof setTimeout> | undefined;
  invisibleBehavior: InvisiblesBehavior | undefined;
} = {
  isConnected: false,
  isIdle: true,
  mutateTimer: undefined,
  invisibleBehavior: undefined,
};
