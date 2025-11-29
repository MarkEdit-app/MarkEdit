# markedit-hello

A test package for the MarkEdit workspace setup.

## Purpose

This package serves as a proof-of-concept for the CoreEditor monorepo structure. It demonstrates:

- Local package creation within the workspace
- Vite-based build system
- Shared configuration (ESLint and TypeScript configs inherited from root)
- Package dependencies within the workspace

## Usage

```typescript
import { sayHello, getVersion } from 'markedit-hello';

console.log(sayHello('Developer')); // Hello, Developer! Welcome to MarkEdit.
console.log(getVersion()); // 1.0.0
```

## Development Scripts

```bash
# Run linter
yarn lint

# Build for production (outputs both ESM and CommonJS)
yarn build

# Run development server
yarn dev

# Clean build artifacts
yarn clean
```

## Build Output

The package builds to both formats:
- `dist/index.cjs` - CommonJS format (for Node.js)
- `dist/index.js` - ES Module format (for modern bundlers)
- `dist/index.d.ts` - TypeScript type definitions

## Configuration

This package reuses configurations from the main package:
- **ESLint**: Extends `../../eslint.config.mjs` 
- **TypeScript**: Extends `../../tsconfig.json`
- **Vite**: Custom config for library build mode

This approach avoids configuration duplication across packages while maintaining consistency.

## Development

This package is part of the CoreEditor workspace. To make changes:

1. Edit files in `src/`
2. Run `yarn lint` to check code style (runs workspace-level linting)
3. Run `yarn build` to compile
4. The compiled output will be in `dist/`
