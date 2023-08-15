import { Decoration, MatchDecorator } from '@codemirror/view';
import { createDecoPlugin } from '../helper';

// Fragile approach, but we only use it for link clicking, it should be fine
const regexp = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-z]{2,16}\b([-a-zA-Z0-9@:%_+.~#?&//=]*)|(\[.*?\]\()(.+?)\)/g;
const className = 'cm-md-link';

export const linkStyle = createDecoPlugin(() => {
  const matcher = new MatchDecorator({
    regexp,
    boundary: /\S/,
    decorate: (add, from, to, match) => {
      const deco = Decoration.mark({
        class: className,
        attributes: {
          title: window.config.localizable?.cmdClickToOpenLink ?? '',
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

export function startClickable() {
  forEachLink(link => {
    link.style.cursor = 'pointer';
    link.style.textDecoration = 'underline';
  });
}

export function stopClickable() {
  forEachLink(link => {
    link.style.cursor = '';
    link.style.textDecoration = '';
  });
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

function forEachLink(handler: (element: HTMLElement) => void) {
  const links = document.querySelectorAll(`.${className}`);
  links.forEach(handler);
}

function extractLink(target: EventTarget | null) {
  const selector = `.${className}`;
  const element = (target as HTMLElement | null)?.closest<HTMLElement>(selector);

  // The link is clickable when it has an underline
  if (element?.style.textDecoration !== 'underline') {
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
