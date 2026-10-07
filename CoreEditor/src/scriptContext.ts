const contextFactories = new WeakMap<object, (filePath: string, capability?: string) => object>();
const reflectGet = Reflect.get;
const reflectApply = Reflect.apply;

interface ContextualScript {
  path: string;
  capability?: string;
}

/**
 * Create script-local MarkEdit and require bindings, scoping opted-in APIs to filePath.
 */
export function createScriptContext(filePath: string, capability?: string) {
  const boundValues = new Map<PropertyKey, object>();
  for (const property of Object.keys(MarkEdit)) {
    const value: unknown = reflectGet(MarkEdit, property);
    const factory = typeof value === 'function' ? contextFactories.get(value) : undefined;
    if (factory !== undefined) {
      boundValues.set(property, factory(filePath, capability));
    }
  }

  const getBound = boundValues.get.bind(boundValues);
  const api = new Proxy(MarkEdit, {
    get(target, property) {
      return getBound(property) ?? reflectGet(target, property);
    },
  });

  const apiModule = { MarkEdit: api };
  const require = typeof window.require === 'function' ? new Proxy(window.require, {
    apply(target, thisArg, args) {
      return args[0] === 'markedit-api' ? apiModule : reflectApply(target, thisArg, args);
    },
  }) : undefined;

  return { MarkEdit: api, require };
}

/**
 * Register a factory for a script-local API function or object.
 */
export function withScriptContext<API extends object>(factory: (filePath: string, capability?: string) => API): API {
  const unbound = () => {
    throw new Error('This API requires a script-local MarkEdit instance.');
  };

  // Reject both calls and property access until a script-local lookup resolves the factory.
  const placeholder: object = new Proxy(unbound, { get: unbound });
  contextFactories.set(placeholder, factory);
  return placeholder as API;
}

/**
 * Prepare bindings up front; each separately injected script can claim its context once.
 */
export function createScriptRunner(scripts: ContextualScript[]) {
  const contexts = new Map(scripts.map(script => [
    script.capability ?? script.path,
    createScriptContext(script.path, script.capability),
  ]));

  const getContext = contexts.get.bind(contexts);
  const deleteContext = contexts.delete.bind(contexts);

  return (key: string, execute: (api: typeof MarkEdit, require: typeof window.require | undefined) => void) => {
    const context = getContext(key);
    if (context === undefined) {
      throw new Error('Script context is unavailable.');
    }

    deleteContext(key);
    execute(context.MarkEdit, context.require);
  };
}
