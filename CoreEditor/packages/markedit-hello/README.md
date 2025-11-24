# markedit-hello

A test package for the MarkEdit workspace setup.

## Purpose

This package serves as a proof-of-concept for the CoreEditor monorepo structure. It demonstrates:

- Local package creation within the workspace
- TypeScript compilation
- Package dependencies within the workspace

## Usage

```typescript
import { sayHello, getVersion } from 'markedit-hello';

console.log(sayHello('Developer')); // Hello, Developer! Welcome to MarkEdit.
console.log(getVersion()); // 1.0.0
```

## Building

```bash
yarn build
```

## Development

This package is part of the CoreEditor workspace. To make changes:

1. Edit files in `src/`
2. Run `yarn build` to compile
3. The compiled output will be in `dist/`
