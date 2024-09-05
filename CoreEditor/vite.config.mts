import { createLogger, defineConfig } from 'vite';

export default defineConfig(({ command }) => (
  {
    base: command === 'build' ? '/chunk-loader/' : '',
    build: {
      assetsDir: 'chunks',
      chunkSizeWarningLimit: 768,
    },
    customLogger: (() => {
      const logger = createLogger();
      const warn = logger.warn;

      logger.warn = (message, options) => {
        // Ignore CodeMirror dynamic import warnings since we are not going to do anything (#214)
        if (message.includes('@vendor/language-data') && message.includes('dynamic import will not move module into another chunk')) {
          return;
        }

        warn(message, options);
      };

      return logger;
    })(),
  }
));
