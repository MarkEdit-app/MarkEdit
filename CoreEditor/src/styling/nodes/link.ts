import { Decoration, MatchDecorator } from '@codemirror/view';
import { Compartment } from '@codemirror/state';
import { clickableLinks as compartments } from '../../common/store';
import { startEffect, stopEffect } from '../matchers/stateful';

// Fragile approach, but we only use it for link clicking, it should be fine
const regexp = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-z]{2,16}\b([-a-zA-Z0-9@:%_+.~#?&//=]*)|(\[.*?\]\()(.+?)\)/g;
const className = 'cm-md-link';

const matcher = new MatchDecorator({
  regexp,
  boundary: /\S/,
  decorate: (add, from, to, match) => {
    const deco = Decoration.mark({ class: className });
    if (match[3]) {
      // Markdown links, only decorate the part inside parentheses
      add(from + match[3].length, to - 1, deco);
    } else {
      // Normal links, decorate the full match
      add(from, to, deco);
    }
  },
});

export function startClickable() {
  const compartment = new Compartment;
  compartments.push(compartment);
  startEffect(compartment, matcher.createDeco(window.editor));
}

export function stopClickable() {
  stopEffect(compartments);
  compartments.length = 0;
}

export function handleMouseDown(event: MouseEvent) {
  if (compartments.length > 0 && extractLink(event.target) !== undefined) {
    event.stopPropagation();
    event.preventDefault();
  }
}

export function handleMouseUp(event: MouseEvent) {
  if (compartments.length > 0) {
    const link = extractLink(event.target);
    if (link !== undefined) {
      window.open(link, '_blank');
      stopClickable();
    }
  }
}

function extractLink(target: EventTarget | null) {
  const selector = `.${className}`;
  const element = (target as HTMLElement).closest<HTMLElement>(selector);
  const link = element?.innerText;

  // It's OK to have a trailing period in a valid url,
  // but generally it's the end of a sentence and we want to remove the period.
  if (link?.endsWith('.') === true && link.endsWith('..') !== true) {
    return link.slice(0, -1);
  }

  return link;
}
