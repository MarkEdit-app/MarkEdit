import { defineConfig } from 'vite';
import dts from 'vite-plugin-dts';

export default defineConfig({
  build: {
    lib: {
      entry: './src/index.ts',
      name: 'MarkEditHello',
      fileName: (format) => `index.${format === 'cjs' ? 'cjs' : 'js'}`,
      formats: ['cjs', 'es'],
    },
    outDir: 'dist',
    rollupOptions: {
      external: [],
    },
  },
  plugins: [
    dts({
      insertTypesEntry: true,
    }),
  ],
});
