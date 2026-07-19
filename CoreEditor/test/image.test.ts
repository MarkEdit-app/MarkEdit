import { afterEach, describe, expect, test } from '@jest/globals';
import { imagePreviewStyle, imageSource } from '../src/styling/nodes/image';
import { sleep } from './utils/helpers';
import * as editor from './utils/editor';

afterEach(() => {
  window.editor.destroy();
  document.body.innerHTML = '';
});

describe('Markdown image previews', () => {
  test('renders an inline image after its editable source', async () => {
    editor.setUp('Before ![Mountain view](images/morning.png "Morning") after', imagePreviewStyle);
    await sleep(50);

    const wrapper = document.querySelector<HTMLElement>('.cm-md-imagePreview');
    const image = wrapper?.querySelector('img');

    expect(wrapper).not.toBeNull();
    expect(wrapper?.hidden).toBe(true);
    expect(image?.getAttribute('src')).toBe('image-loader://images%2Fmorning.png');
    expect(image?.alt).toBe('Mountain view');
    expect(image?.title).toBe('Morning');
    expect(editor.getText()).toBe('Before ![Mountain view](images/morning.png "Morning") after');

    image?.dispatchEvent(new Event('load'));
    expect(wrapper?.hidden).toBe(false);

    image?.dispatchEvent(new Event('error'));
    expect(wrapper?.hidden).toBe(true);
  });

  test('renders reference-style images', async () => {
    editor.setUp('![Mountain][photo]\n\n[photo]: images/morning.png', imagePreviewStyle);
    await sleep(50);

    const image = document.querySelector<HTMLImageElement>('.cm-md-imagePreviewImage');
    expect(image?.getAttribute('src')).toBe('image-loader://images%2Fmorning.png');
    expect(image?.alt).toBe('Mountain');
  });

  test('does not render ordinary Markdown links', async () => {
    editor.setUp('[Mountain](images/morning.png)', imagePreviewStyle);
    await sleep(50);

    expect(document.querySelector('.cm-md-imagePreview')).toBeNull();
  });
});

describe('imageSource', () => {
  test('routes relative file paths through the native loader', () => {
    expect(imageSource('../Images/Morning View.png'))
      .toBe('image-loader://..%2FImages%2FMorning%20View.png');
  });

  test('keeps remote and data sources intact', () => {
    expect(imageSource('https://example.com/image.png')).toBe('https://example.com/image.png');
    expect(imageSource('data:image/png;base64,abc')).toBe('data:image/png;base64,abc');
    expect(imageSource('//example.com/image.png')).toBe('//example.com/image.png');
    expect(imageSource('file:///Users/example/image.png')).toBe('');
    expect(imageSource('javascript:alert(1)')).toBe('');
  });

  test('normalizes angle brackets and Markdown escapes', () => {
    expect(imageSource('<images/Morning View.png>'))
      .toBe('image-loader://images%2FMorning%20View.png');
    expect(imageSource('images/Morning%20View.png'))
      .toBe('image-loader://images%2FMorning%20View.png');
    expect(imageSource('images/morning\\(final\\).png'))
      .toBe('image-loader://images%2Fmorning(final).png');
  });
});
