const loadModule = url => import(url);
const render = globalThis.__MARKEDIT_PREVIEW_RENDERER__;
const container = globalThis.document.querySelector('#container');

const updateScroll = () => {
  globalThis.document.documentElement.classList.toggle('preview-scrolled', globalThis.scrollY > 0);
};

globalThis.addEventListener('scroll', updateScroll, { passive: true });
updateScroll();

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

globalThis.addEventListener('message', event => {
  if (event.source !== globalThis.parent || event.data?.type !== 'preview-colors') {
    return;
  }

  const { background, text } = event.data;
  if (typeof background === 'string' && typeof text === 'string') {
    const style = globalThis.document.documentElement.style;
    style.setProperty('--preview-background', background);
    style.setProperty('--preview-text', text);
  }
});
