import { PasteboardItem } from 'markedit-api';

export async function getPasteboardItems(): Promise<PasteboardItem[]> {
  const items = await window.nativeModules.api.getPasteboardItems();
  return items === undefined ? [] : JSON.parse(items);
}

export function getPasteboardString(): Promise<string | undefined> {
  return window.nativeModules.api.getPasteboardString();
}
