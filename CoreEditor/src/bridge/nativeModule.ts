import { isReleaseMode } from '../common/utils';

/**
 * Module used to send message to native.
 */
export interface NativeModule {
  name: string;
}

/**
 * Create a Proxy for redirecting messages to native by relying on messageHandlers.
 *
 * @param moduleName name of the native module
 * @returns The created proxy
 */
export function createNativeModule<T extends NativeModule>(moduleName: string): T {
  return new Proxy({} as T, {
    get(_target, p): ((args?: Map<string, unknown>) => Promise<unknown>) | undefined {
      if (typeof p !== 'string') {
        return undefined;
      }

      // eslint-disable-next-line compat/compat
      return args => new Promise((resolve, reject) => {
        const message = {
          moduleName,
          methodName: p,
          parameters: JSON.stringify(args ?? {}),
        };

        // Message is serialized and sent to native here
        if (isReleaseMode) {
          // eslint-disable-next-line promise/prefer-await-to-then
          window.webkit?.messageHandlers?.bridge?.postMessage(message).then(resolve, reject);
        } else {
          console.log(message);
        }
      });
    },
  });
}
