import { fileURLToPath } from 'url';
import { defineConfig } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

export default defineConfig({
  root: './src/@light',
  resolve: {
    alias: {
      '@codemirror/lang-markdown': fileURLToPath(new URL('../@vendor/lang-markdown', import.meta.url)),
    },
  },
  build: {
    outDir: './dist',
  },
  plugins: [viteSingleFile()],
});
