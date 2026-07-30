/** @type { import('ts-jest').JestConfigWithTsJest } */

// eslint-disable-next-line no-undef
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  setupFiles: ['<rootDir>/test/utils/setup.ts'],
  moduleNameMapper: {
    '^@codemirror/lang-html$': '<rootDir>/src/@vendor/lang-html',
    '^@codemirror/lang-markdown$': '<rootDir>/src/@vendor/lang-markdown',
  },
};
