import { FileVersion } from 'markedit-api';

export async function getFileVersions(): Promise<FileVersion[]> {
  const json = await window.nativeModules.api.getFileVersions();
  if (json === undefined) {
    return [];
  }

  const versions: { id: string; modificationDate: number }[] = JSON.parse(json);
  return versions.map(version => ({
    id: version.id,
    modificationDate: new Date(version.modificationDate * 1000),
  }));
}

export async function getFileVersionContent(id: string): Promise<string | undefined> {
  return window.nativeModules.api.getFileVersionContent({ id });
}

export async function restoreFileVersion(id: string): Promise<boolean> {
  return window.nativeModules.api.restoreFileVersion({ id });
}

export async function deleteFileVersions(ids: string[]): Promise<boolean> {
  return window.nativeModules.api.deleteFileVersions({ ids });
}
