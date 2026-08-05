# UpdaterCore

This package provides the trust rules for in-place app updates: code signature verification and the naming of staging directories.

It is used by `UpdateInstaller`, the XPC service that installs updates, and is deliberately free of any app or UI dependency.
