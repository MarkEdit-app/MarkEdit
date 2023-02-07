import { defineConfig } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

export default defineConfig({
  root: './src/@light',
  build: {
    outDir: './dist',
  },
  plugins: [viteSingleFile()],
});
