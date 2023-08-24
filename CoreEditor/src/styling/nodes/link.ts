import { Decoration, MatchDecorator } from '@codemirror/view';
import { createDecoPlugin } from '../helper';
import { isMetaKeyDown } from '../../events';

// Fragile approach, but we only use it for link clicking, it should be fine
const regexp = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-z]{2,16}\b([-a-zA-Z0-9@:%_+.~#?&//=]*)|(\[.*?\]\()(.+?)\)/g;
const className = 'cm-md-link';

declare global {
  interface Window {
    _startLinkClickable: (_: HTMLElement) => void;
    _stopLinkClickable: (_: HTMLElement) => void;
  }
}

export const linkStyle = createDecoPlugin(() => {
  window._startLinkClickable = startClickable;
  window._stopLinkClickable = stopClickable;

  const matcher = new MatchDecorator({
    regexp,
    boundary: /\S/,
    decorate: (add, from, to, match) => {
      const deco = Decoration.mark({
        class: className,
        attributes: {
          title: window.config.localizable?.cmdClickToOpenLink ?? '',
          onmouseenter: '_startLinkClickable(this)',
          onmouseleave: '_stopLinkClickable(this)',
        },
      });

      if (match[3]) {
        // Markdown links, only decorate the part inside parentheses
        add(from + match[3].length, to - 1, deco);
      } else {
        // Normal links, decorate the full match
        add(from, to, deco);
      }
    },
  });

  return matcher.createDeco(window.editor);
});

export function startClickable(inputElement?: HTMLElement) {
  const linkElement = inputElement ?? storage.focusedElement;
  storage.focusedElement = linkElement;

  if (linkElement === undefined || !isMetaKeyDown()) {
    return;
  }

  linkElement.title = '';
  linkElement.style.cursor = 'pointer';
  linkElement.style.textDecoration = 'underline';

  // Find the actual text node and use its color
  const text = [...linkElement.children].find(node => node.textContent !== null);
  if (text !== undefined) {
    linkElement.style.textDecorationColor = getComputedStyle(text).color;
  }
}

export function stopClickable(inputElement?: HTMLElement) {
  const linkElement = inputElement ?? storage.focusedElement;
  storage.focusedElement = inputElement ? undefined : storage.focusedElement;

  if (linkElement === undefined) {
    return;
  }

  linkElement.title = window.config.localizable?.cmdClickToOpenLink ?? '';
  linkElement.style.cursor = '';
  linkElement.style.textDecoration = '';
  linkElement.style.textDecorationColor = '';
}

export function handleMouseDown(event: MouseEvent) {
  if (extractLink(event.target) !== undefined) {
    event.stopPropagation();
    event.preventDefault();
  }
}

export function handleMouseUp(event: MouseEvent) {
  const link = extractLink(event.target);
  if (link !== undefined) {
    window.open(link, '_blank');
  }
}

function extractLink(target: EventTarget | null) {
  const selector = `.${className}`;
  const element = (target as HTMLElement | null)?.closest<HTMLElement>(selector);

  // The element doesn't belong to a Markdown link
  if (element === null || element === undefined) {
    return undefined;
  }

  // The link is clickable when it has an underline,
  // use includes because Chrome merges textDecorationColor into textDecoration.
  if (!element.style.textDecoration.includes('underline')) {
    return undefined;
  }

  // It's OK to have a trailing period in a valid url,
  // but generally it's the end of a sentence and we want to remove the period.
  const link = element.innerText;
  if (link.endsWith('.') === true && link.endsWith('..') !== true) {
    return link.slice(0, -1);
  }

  return link;
}

const storage: {
  focusedElement: HTMLElement | undefined;
} = {
  focusedElement: undefined,
};
