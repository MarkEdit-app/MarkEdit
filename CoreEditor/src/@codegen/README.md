# @codegen

This folder contains the code generation templates for the bridge between the web application and native code.

It uses [ts-gyb](https://github.com/microsoft/ts-gyb) to analyze TypeScript interfaces and generate Swift code.

Native and web bridges are main-actor isolated. Generated configuration and named payload types
conform to `Sendable`, so background processing can receive value snapshots without sharing bridge
or WebKit state. Keep payload fields sendable when extending the TypeScript interfaces.