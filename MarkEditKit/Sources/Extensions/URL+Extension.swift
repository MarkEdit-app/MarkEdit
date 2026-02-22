//
//  URL+Extension.swift
//
//  Created by cyan on 1/15/23.
//

import Foundation

public extension URL {
  var localizedName: String {
    (try? resourceValues(forKeys: Set([.localizedNameKey])))?.name ?? lastPathComponent
  }

  var resolvingSymbolicLink: URL {
    guard isSymbolicLink else {
      return self
    }

    do {
      let resolvedPath = try FileManager.default.destinationOfSymbolicLink(atPath: path)
      return URL(filePath: resolvedPath)
    } catch {
      return self
    }
  }

  func replacingPathExtension(_ pathExtension: String) -> URL {
    deletingPathExtension().appendingPathExtension(pathExtension)
  }
}

// MARK: - Private

private extension URL {
  var isSymbolicLink: Bool {
    (try? resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false
  }
}
