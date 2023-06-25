# MarkEdit

[![](https://img.shields.io/badge/Platform-macOS_12.0+-blue?color=007bff)](https://apps.apple.com/app/id1669953820) [![](https://github.com/MarkEdit-app/MarkEdit/actions/workflows/build-and-test.yml/badge.svg?branch=main)](https://github.com/MarkEdit-app/MarkEdit/actions/workflows/build-and-test.yml)

MarkEdit is a free and **open-source** Markdown editor, for macOS. It's just like _TextEdit_ on Mac but dedicated to `Markdown`.

<a href="https://apps.apple.com/app/id1669953820" target="_blank"><img alt="Download on the Mac App Store" src="https://user-images.githubusercontent.com/6745066/216816394-706b5104-42f3-4cc4-96c9-471a9356d1a8.svg"></a>

## Screenshots

![Screenshots 01](/Screenshots/01.png)

![Screenshots 02](/Screenshots/02.png)

![Screenshots 03](/Screenshots/03.png)

## What make MarkEdit different

- Privacy focused: doesn't collect any user data
- Native: clean and intuitive, feels right at home on Mac
- Fast: edits 10 MB files easily
- Lightweight: installer size is about 3 MB
- Extensible: seamless Shortcuts integration

To learn more, refer to [Philosophy](https://github.com/MarkEdit-app/MarkEdit/wiki/Philosophy) and [Why MarkEdit](https://github.com/MarkEdit-app/MarkEdit/wiki/Why-MarkEdit).

## Why is MarkEdit Free

MarkEdit is completely free and open source, with no advertising or promotions for other services. We ship it because we love it, and we don't expect any revenue from it.

Please consider starring this project and leaving a nice review on the [Mac App Store](https://markedit.app), your support is all we need.

## Using MarkEdit

Please refer to the [wiki page](https://github.com/MarkEdit-app/MarkEdit/wiki) for details.

## Building MarkEdit

### Building CoreEditor

After checking out the project, go to the root folder of the repository and run:

```
cd CoreEditor
yarn install
yarn build
```

> To test the editor in a dev environment, run `yarn dev` instead, web interfaces are exposed to `window.webModules`.

### Building MarkEditMac

After successfully building `CoreEditor`, open `MarkEdit.xcodeproj`, and build the `MarkEditMac` target.

It's recommended to override build settings by adding a `Local.xcconfig` file under the root folder, including code signing identity, development team, etc.

> Note that you should always use the latest stable release of Xcode.

## Testing MarkEdit Locally

Unit tests are run automatically by [GitHub Actions](https://github.com/MarkEdit-app/MarkEdit/actions), you can also run them on your machine.

### Testing CoreEditor

Make sure dependencies are installed and run:

```
cd CoreEditor
yarn test
```

### Testing MarkEditMac

MarkEditMac consists of several targets, here's an example of testing `MarkEditCoreTests`:

```
xcodebuild test -project MarkEdit.xcodeproj -scheme MarkEditCoreTests -destination 'platform=macOS'
```

## Contributing to MarkEdit

For bug reports, please [open an issue](https://github.com/MarkEdit-app/MarkEdit/issues/new).

For code changes, bug fixes are generally welcomed, feel free to [open pull requests](https://github.com/MarkEdit-app/MarkEdit/compare). However, we hesitate to add new features ([why](https://github.com/MarkEdit-app/MarkEdit/wiki/Why-MarkEdit#feature-poor)), please fork the repository and make your own.

For localization, please also open an issue as mentioned above first.

Thanks in advance.

## Acknowledgments

MarkEdit is built on top of the awesome [CodeMirror 6](https://codemirror.net/) project.

MarkEdit has built-in proofing support based on [Grammarly](https://grammarly.com/).

MarkEdit uses [ts-gyb](https://github.com/microsoft/ts-gyb) to generate lots of boilerplate code.
