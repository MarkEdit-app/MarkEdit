<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/MarkEdit-app/MarkEdit/main/Icon.png" width="96">
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/MarkEdit-app/MarkEdit/main/Icon-dark.png" width="96">
  <img src="./Icon.png" width="96">
</picture>

# MarkEdit

[![](https://img.shields.io/badge/Platform-macOS_15.0+-blue?color=007bff)](https://github.com/MarkEdit-app/MarkEdit?tab=readme-ov-file#platform-compatibility) [![](https://github.com/MarkEdit-app/MarkEdit/actions/workflows/build-and-test.yml/badge.svg?branch=main)](https://github.com/MarkEdit-app/MarkEdit/actions/workflows/build-and-test.yml)

MarkEdit is a free and **open-source** Markdown editor, for macOS. It's just like _TextEdit_ on Mac but dedicated to `Markdown`.

> [!TIP]
> Discover our other free and open-source apps at [libremac.github.io](https://libremac.github.io/).
>
> Follow our Mastodon account [@MarkEditApp](https://mastodon.social/@MarkEditApp) for the latest updates.

## Screenshots

![Screenshots 01](/Screenshots/01.png)

![Screenshots 02](/Screenshots/02.png)

![Screenshots 03](/Screenshots/03.png)

## What makes MarkEdit different

- Privacy-focused: doesn't collect any user data
- Native: clean and intuitive, feels right at home on Mac
- Fast: edits 10 MB files easily
- Lightweight: installer size is about 4 MB
- Extensible: seamless integration with Shortcuts and AppleScript

MarkEdit is designed to be simple and easy to use. You can also customize the UI and behavior by adding your own scripts, including utilizing CodeMirror extensions.

For example, use [MarkEdit-preview](https://github.com/MarkEdit-app/MarkEdit-preview) to add a preview pane, and [MarkEdit-theming](https://github.com/MarkEdit-app/MarkEdit-theming) to customize themes.

On macOS Tahoe, you can also use [MarkEdit-ai-writer](https://github.com/MarkEdit-app/MarkEdit-ai-writer) to effortlessly access Apple's generative language models.

> To learn more, refer to [Philosophy](https://github.com/MarkEdit-app/MarkEdit/wiki/Philosophy), [Why MarkEdit](https://github.com/MarkEdit-app/MarkEdit/wiki/Why-MarkEdit) and [MarkEdit-api](https://github.com/MarkEdit-app/MarkEdit-api).

## Installation

Get `MarkEdit.dmg` from the <a href="https://github.com/MarkEdit-app/MarkEdit/releases/latest" target="_blank">latest release</a>, open it, and drag `MarkEdit.app` to `Applications`.

<img src="./Screenshots/install.png" width="540" alt="Install MarkEdit">

MarkEdit checks for updates automatically. You can also check manually via the main `MarkEdit` menu, or browse version history [here](https://github.com/MarkEdit-app/MarkEdit/releases).

If you prefer a [Homebrew](https://brew.sh/) installation, run `brew install markedit` in your terminal and you're all set.

> We used to publish MarkEdit to the Mac App Store, [but no longer](https://github.com/MarkEdit-app/MarkEdit/wiki/Philosophy#be-a-good-macos-citizen). Don't worry about the security warning; releases are signed with a certificate from an identified developer and [notarized](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).

## Platform Compatibility

To be focused, we only support the latest two major macOS releases. For now, they are [macOS Sequoia](https://www.apple.com/macos/macos-sequoia/) and [macOS Tahoe](https://www.apple.com/os/macos/).

Last-compatible version tags: [macos-12](https://github.com/MarkEdit-app/MarkEdit/releases/tag/macos-12), [macos-13](https://github.com/MarkEdit-app/MarkEdit/releases/tag/macos-13), [macos-14](https://github.com/MarkEdit-app/MarkEdit/releases/tag/macos-14).

## Why MarkEdit is free

MarkEdit is completely free and open-source, with no advertising or promotions for other services. We make it mostly because we need it, and we ship it just in case you need it too.

Please consider starring or contributing to this project.

> For everyone's convenience, MarkEdit is licensed under the MIT license. However, please don't upload the app to the Mac App Store unless you add meaningful new value (see [also](https://github.com/MarkEdit-app/MarkEdit/wiki#last-but-not-least)).

## Using MarkEdit

Please refer to the [wiki page](https://github.com/MarkEdit-app/MarkEdit/wiki/Manual) for details.

## Development

Please refer to the [wiki page](https://github.com/MarkEdit-app/MarkEdit/wiki/Development) for details.

## Contributing to MarkEdit

For bug reports, please [open an issue](https://github.com/MarkEdit-app/MarkEdit/issues/new).

For code changes, bug fixes are generally welcomed, feel free to [open pull requests](https://github.com/MarkEdit-app/MarkEdit/compare). However, we hesitate to add new features ([why](https://github.com/MarkEdit-app/MarkEdit/wiki/Why-MarkEdit#feature-poor)); please fork the repository and make your own.

For localization, we don't plan to add new languages, as maintaining high quality across them would be difficult for us.

Thanks in advance.

## Acknowledgments

MarkEdit is built on top of the awesome [CodeMirror 6](https://codemirror.net/) project.

MarkEdit uses [ts-gyb](https://github.com/microsoft/ts-gyb) to generate lots of boilerplate code.
