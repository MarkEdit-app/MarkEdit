import { spawn } from 'node:child_process';
import process from 'node:process';
import { URL, fileURLToPath } from 'node:url';
import { createServer } from 'vite';

if (process.platform !== 'darwin') {
  throw new Error('Browser tests require macOS and the Xcode command-line tools.');
}

const server = await createServer({ server: { host: '127.0.0.1', port: 0 } });
try {
  await server.listen();
  const baseURL = server.resolvedUrls?.local[0];
  if (baseURL === undefined) {
    throw new Error('Vite did not provide a browser-test URL.');
  }

  const runner = fileURLToPath(new URL('./WebKitRunner.swift', import.meta.url));
  const url = new URL('/test/browser/semantic-highlighting.html', baseURL).href;
  await new Promise((resolve, reject) => {
    const child = spawn('xcrun', ['swift', runner, url], { stdio: 'inherit' });
    child.once('error', reject);
    child.once('exit', (code, signal) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`WebKit browser tests failed (${signal ?? code}).`));
      }
    });
  });
} finally {
  await server.close();
}
