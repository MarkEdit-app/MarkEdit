import { CreateFileOptions, DirectoryType, FileInfo, FileObject } from 'markedit-api';

export async function createFile(options: CreateFileOptions): Promise<boolean> {
  return window.nativeModules.api.createFile({ options });
}

export async function deleteFile(path: string): Promise<boolean> {
  return window.nativeModules.api.deleteFile({ path });
}

export async function listFiles(path: string): Promise<string[] | undefined> {
  return window.nativeModules.api.listFiles({ path });
}

export async function getFileContent(path?: string): Promise<string | undefined> {
  return window.nativeModules.api.getFileContent({ path });
}

export async function getFileObject(path?: string): Promise<FileObject | undefined> {
  const object = await window.nativeModules.api.getFileObject({ path });
  return object === undefined ? undefined : JSON.parse(object);
}

export async function getFileInfo(path?: string): Promise<FileInfo | undefined> {
  const info = await window.nativeModules.api.getFileInfo({ path });
  return info === undefined ? undefined : (() => {
    const json: {
      filePath: string;
      fileSize: number;
      creationDate: number;
      modificationDate: number;
      parentPath: string;
      isDirectory: boolean;
    } = JSON.parse(info);

    return {
      filePath: json.filePath,
      fileSize: json.fileSize,
      creationDate: new Date(json.creationDate * 1000),
      modificationDate: new Date(json.modificationDate * 1000),
      parentPath: json.parentPath,
      isDirectory: json.isDirectory,
    };
  })();
}

export function getDirectoryPath(type: DirectoryType): string {
  return window.config.standardDirectories[type];
}
