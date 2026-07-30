import { fileURLToPath } from 'url';
import { defineConfig } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

export default defineConfig({
  resolve: {
    alias: {
      '@codemirror/lang-html': fileURLToPath(new URL('./src/@vendor/lang-html', import.meta.url)),
      '@codemirror/lang-markdown': fileURLToPath(new URL('./src/@vendor/lang-markdown', import.meta.url)),
    },
  },
  plugins: [viteSingleFile()],
});
