import { v4 as UUID } from 'uuid';
import { isProd, isWebKit } from '../common/utils';

/**
 * Module used to send message to native.
 */
export interface NativeModule {
  name: string;
}

/**
 * Reply sent back from native.
 */
export interface NativeReply {
  id: string;
  result?: unknown;
  error?: string;
}

const callbacks: Record<string, (reply: NativeReply) => void> = {};

/**
 * Create a Proxy for redirecting messages to native by relying on messageHandlers.
 *
 * @param moduleName name of the native module
 * @returns The created proxy
 */
export function createNativeModule<T extends NativeModule>(moduleName: string): T {
  return new Proxy({} as T, {
    get(_target, p): ((args?: Record<string, unknown>) => Promise<unknown>) | undefined {
      if (typeof p !== 'string') {
        return undefined;
      }

      // eslint-disable-next-line compat/compat
      return args => new Promise((resolve, reject) => {
        // Context is saved to callbacks,
        // we will retrieve it in handleNativeReply later
        const id = UUID();
        callbacks[id] = (reply: NativeReply) => {
          if (reply.error === undefined) {
            resolve(reply.result);
          } else {
            reject(new Error(reply.error));
          }
        };

        const message = {
          id,
          moduleName,
          methodName: p,
          parameters: JSON.stringify(args ?? {}),
        };

        // Message is serialized and sent to native here
        if (isWebKit) {
          window.webkit?.messageHandlers?.bridge?.postMessage(message);
        }

        if (!isProd) {
          console.log(message);
        }
      });
    },
  });
}

/**
 * Native invokes this to reply to a message sent by web.
 */
export function handleNativeReply(reply: NativeReply) {
  const callback = callbacks[reply.id] as ((reply: NativeReply) => void) | undefined;
  if (callback == undefined) {
    return;
  }

  callback(reply);
  delete callbacks[reply.id];
}
