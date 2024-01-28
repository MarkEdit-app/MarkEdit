import { createLogger, defineConfig } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

export default defineConfig({
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
  plugins: [viteSingleFile()],
});
