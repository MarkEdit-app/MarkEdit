export interface ModuleLoader {
  <Module>(url: string): Promise<Module>;
}

export default function loadModule<Module>(url: string): Promise<Module> {
  return import(/* @vite-ignore */ url) as Promise<Module>;
}
