import globals from 'globals';
import parser from '@typescript-eslint/parser';
import js from '@eslint/js';
import ts from 'typescript-eslint';
import compat from 'eslint-plugin-compat';
import promise from 'eslint-plugin-promise';
import stylistic from '@stylistic/eslint-plugin';

export default [
  {
    ignores: [
      '.yarn',
      'dist/*',
      'src/@vendor/*',
    ],
  },
  js.configs.recommended,
  ...ts.configs.recommended,
  compat.configs['flat/recommended'],
  promise.configs['flat/recommended'],
  {
    plugins: {
      '@stylistic': stylistic,
    },
    languageOptions: {
      globals: {
        ...globals.browser,
      },
      parser,
      parserOptions: {
        project: [
          'tsconfig.json',
        ],
      },
    },
    files: ['**/*.ts', '**/*.tsx', '**/*.mts'],
    rules: {
      'no-case-declarations': 'error',
      'no-prototype-builtins': 'error',
      'no-array-constructor': 'error',
      'no-new-wrappers': 'error',
      'eol-last': 'error',

      'no-restricted-syntax': [
        'error',
        {
          'selector': 'TSEnumDeclaration[const=true]',
          'message': 'Always use enum and not const enum. TypeScript enums already cannot be mutated; const enum is a separate language feature related to optimization that makes the enum invisible to JavaScript users of the module.',
        },
        {
          'selector': 'ArrowFunctionExpression[parent.type=\'PropertyDefinition\'][parent.parent.type=\'ClassBody\']',
          'message': 'Arrow functions are not allowed in class properties. Define as a method instead.',
        },
      ],

      '@typescript-eslint/no-non-null-assertion': 'error',
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-empty-object-type': ['error', { allowInterfaces: 'always' }],
      '@typescript-eslint/no-unnecessary-condition': 'error',
      '@typescript-eslint/no-unnecessary-type-arguments': 'error',
      '@typescript-eslint/no-unnecessary-type-constraint': 'error',
      '@typescript-eslint/no-unsafe-argument': 'error',
      '@typescript-eslint/prefer-optional-chain': 'error',
      '@typescript-eslint/prefer-readonly': 'error',
      '@typescript-eslint/strict-boolean-expressions': 'error',
      '@typescript-eslint/switch-exhaustiveness-check': 'error',
      '@typescript-eslint/explicit-member-accessibility': ['error', { accessibility: 'no-public' }],
      '@typescript-eslint/consistent-type-exports': ['error', { fixMixedExportsWithInlineTypeSpecifier: true }],
      '@typescript-eslint/class-literal-property-style': 'error',

      'dot-notation': 'off',
      '@typescript-eslint/dot-notation': 'error',
      'no-dupe-class-members': 'off',
      '@typescript-eslint/no-dupe-class-members': 'error',
      'no-invalid-this': 'off',
      '@typescript-eslint/no-invalid-this': 'error',
      'no-redeclare': 'off',
      '@typescript-eslint/no-redeclare': 'error',
      'no-throw-literal': 'off',
      '@typescript-eslint/only-throw-error': 'error',
      'no-unused-expressions': 'off',
      '@typescript-eslint/no-unused-expressions': 'error',
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { 'ignoreRestSiblings': true, 'argsIgnorePattern': '^_' }],
      'no-return-await': 'off',
      '@typescript-eslint/return-await': 'error',

      'indent': 'off',
      '@stylistic/indent': ['error', 2, {
        SwitchCase: 1,
        ignoredNodes: [
          'TSEnumMember',
          'TSEnumDeclaration > TSEnumMember',
        ],
      }],

      '@stylistic/array-bracket-spacing': ['error', 'never'],
      '@stylistic/member-delimiter-style': 'error',
      '@stylistic/type-annotation-spacing': 'error',
      '@stylistic/brace-style': ['error', '1tbs', { 'allowSingleLine': true }],
      '@stylistic/comma-dangle': ['error', 'always-multiline'],
      '@stylistic/comma-spacing': 'error',
      '@stylistic/function-call-spacing': 'error',
      '@stylistic/keyword-spacing': 'error',
      '@stylistic/no-extra-parens': ['error', 'functions'],
      '@stylistic/object-curly-spacing': ['error', 'always'],
      '@stylistic/quotes': [2, 'single', { 'avoidEscape': true }],
      '@stylistic/semi': 'error',

      'promise/prefer-await-to-then': 'error',
    },
  },
];
