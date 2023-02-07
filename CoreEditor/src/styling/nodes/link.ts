import { Compartment } from '@codemirror/state';
import { clickableLinks as compartments } from '../../common/store';
import { createMarkDeco } from '../matchers/regex';
import { startEffect, stopEffect } from '../matchers/stateful';

// Fragile approach, but we only use it for link clicking, it should be fine
const pattern = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{2,256}\.[a-z]{2,4}\b([-a-zA-Z0-9@:%_+.~#?&//=]*)/g;
const className = 'cm-md-link';

export function startClickable() {
  const compartment = new Compartment;
  compartments.push(compartment);
  startEffect(compartment, createMarkDeco(pattern, className));
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
  return element?.innerText;
}
