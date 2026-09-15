const loadModule = url => import(url);
const render = globalThis.__MARKEDIT_RENDERER__;
const container = globalThis.document.querySelector('#container');

globalThis.document.addEventListener('click', event => {
  if (event.target.closest('a')) {
    event.preventDefault();
  }
});

globalThis.addEventListener('message', async function handleRender(event) {
  if (event.source !== globalThis.parent || event.data?.type !== 'render-preview' || typeof event.data.code !== 'string') {
    return;
  }

  globalThis.removeEventListener(
    'message',
    handleRender,
  );

  try {
    await render(container, event.data.code, loadModule);
  } catch (error) {
    container.setAttribute('role', 'alert');
    container.textContent = String(error);
  } finally {
    globalThis.parent.postMessage({ type: 'preview-rendered' }, '*');
  }
});
