const contextFactories = new WeakMap<object, (filePath: string) => object>();

/**
 * Create script-local MarkEdit and require bindings, scoping opted-in APIs to filePath.
 */
export function createScriptContext(filePath: string) {
  const boundValues = new WeakMap<object, object>();
  const api = new Proxy(MarkEdit, {
    get(target, property) {
      const value: unknown = Reflect.get(target, property);
      if (typeof value !== 'function') {
        return value;
      }

      const factory = contextFactories.get(value);
      if (factory === undefined) {
        return value;
      }

      let bound = boundValues.get(value);
      if (bound === undefined) {
        bound = factory(filePath);
        boundValues.set(value, bound);
      }

      return bound;
    },
  });

  const apiModule = { MarkEdit: api };
  const require = typeof window.require === 'function' ? new Proxy(window.require, {
    apply(target, thisArg, args) {
      return args[0] === 'markedit-api' ? apiModule : Reflect.apply(target, thisArg, args);
    },
  }) : undefined;

  return { MarkEdit: api, require };
}

/**
 * Register a factory for a script-local API function or object.
 */
export function withScriptContext<API extends object>(factory: (filePath: string) => API): API {
  const unbound = () => {
    throw new Error('This API requires a script-local MarkEdit instance.');
  };

  // Reject both calls and property access until a script-local lookup resolves the factory.
  const placeholder: object = new Proxy(unbound, { get: unbound });
  contextFactories.set(placeholder, factory);
  return placeholder as API;
}
