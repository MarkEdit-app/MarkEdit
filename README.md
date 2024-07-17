<img src="./Icon.png" width="96">

# MarkEdit

[![](https://img.shields.io/badge/Platform-macOS_13.0+-blue?color=007bff)](https://github.com/MarkEdit-app/MarkEdit/releases/latest) [![](https://github.com/MarkEdit-app/MarkEdit/actions/workflows/build-and-test.yml/badge.svg?branch=main)](https://github.com/MarkEdit-app/MarkEdit/actions/workflows/build-and-test.yml)

MarkEdit is a free and **open-source** Markdown editor, for macOS. It’s just like _TextEdit_ on Mac but dedicated to `Markdown`.

## Installation

Get `MarkEdit.dmg` from the <a href="https://github.com/MarkEdit-app/MarkEdit/releases/latest" target="_blank">latest release</a>, open it, and drag `MarkEdit.app` to `Applications`.

<img src="./Screenshots/install.png" width="540" alt="Install MarkEdit">

MarkEdit checks for updates automatically. You can also check manually via the main `MarkEdit` menu, or browse version history [here](https://github.com/MarkEdit-app/MarkEdit/releases).

If you prefer a [Homebrew](https://brew.sh/) installation, run `brew install markedit` in your terminal and you’re all set.

> We used to publish MarkEdit to the Mac App Store, [but no longer](https://github.com/MarkEdit-app/MarkEdit/wiki/Philosophy#be-a-good-macos-citizen). Don’t worry about the security warning; releases are signed with a certificate from an identified developer and [notarized](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).

## Platform Compatibility

To be focused, we only support the latest two major macOS releases. For now, they are [macOS Ventura](https://www.apple.com/newsroom/2022/10/macos-ventura-is-now-available/) and [macOS Sonoma](https://www.apple.com/newsroom/2023/09/macos-sonoma-is-available-today/).

Last-compatible version tags: [macos-12](https://github.com/MarkEdit-app/MarkEdit/releases/tag/macos-12).

## Screenshots

![Screenshots 01](/Screenshots/01.png)

![Screenshots 02](/Screenshots/02.png)

![Screenshots 03](/Screenshots/03.png)

## What makes MarkEdit different

- Privacy-focused: doesn’t collect any user data
- Native: clean and intuitive, feels right at home on Mac
- Fast: edits 10 MB files easily
- Lightweight: installer size is about 3 MB
- Extensible: seamless Shortcuts integration

To learn more, refer to [Philosophy](https://github.com/MarkEdit-app/MarkEdit/wiki/Philosophy) and [Why MarkEdit](https://github.com/MarkEdit-app/MarkEdit/wiki/Why-MarkEdit).

## Why MarkEdit is free

MarkEdit is completely free and open-source, with no advertising or promotions for other services. We make it mostly because we need it, and we ship it just in case you need it too.

Please consider starring or contributing to this project.

## Using MarkEdit

Please refer to the [wiki page](https://github.com/MarkEdit-app/MarkEdit/wiki/Manual) for details.

## Development

Please refer to the [wiki page](https://github.com/MarkEdit-app/MarkEdit/wiki/Development) for details.

## Contributing to MarkEdit

For bug reports, please [open an issue](https://github.com/MarkEdit-app/MarkEdit/issues/new).

For code changes, bug fixes are generally welcomed, feel free to [open pull requests](https://github.com/MarkEdit-app/MarkEdit/compare). However, we hesitate to add new features ([why](https://github.com/MarkEdit-app/MarkEdit/wiki/Why-MarkEdit#feature-poor)); please fork the repository and make your own.

For localization, please also open an issue as mentioned above first.

Thanks in advance.

## Acknowledgments

MarkEdit is built on top of the awesome [CodeMirror 6](https://codemirror.net/) project.

MarkEdit uses [ts-gyb](https://github.com/microsoft/ts-gyb) to generate lots of boilerplate code.
