/** @type { import('ts-jest').JestConfigWithTsJest } */

// eslint-disable-next-line no-undef
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  setupFiles: ['<rootDir>/test/setup.ts'],
};
