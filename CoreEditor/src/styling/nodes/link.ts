import { Decoration, EditorView, MatchDecorator } from '@codemirror/view';
import { EditorSelection, Extension } from '@codemirror/state';
import { SyntaxNodeRef } from '@lezer/common';
import { createDecoPlugin } from '../helper';
import { createDecos } from '../matchers/lezer';
import { isReleaseMode } from '../../common/utils';
import { isMetaKeyDown } from '../../modules/events';
import { getNodesNamed } from '../../modules/lezer';

const className = 'cm-md-link';
const regexp = {
  standard: /[a-zA-Z][a-zA-Z0-9+.-]*:\/\/\/?([a-zA-Z0-9-]+\.)?[-a-zA-Z0-9@:%._+~#=]+(\.[a-z]+)?\b([-a-zA-Z0-9@:%._+~#=?&//]*)|(\[.*?\]\()(.+?)[\s)]/g,
  footnote: /^\[\^[^\]]+\]$/,
  reference: /^\[[^\]]+\] ?\[([^\]]+)\]$/,
};

declare global {
  interface Window {
    _startLinkClickable: (_: HTMLElement) => void;
    _stopLinkClickable: (_: HTMLElement) => void;
  }
}

window._startLinkClickable = startClickable;
window._stopLinkClickable = stopClickable;

/**
 * For standard links like `https://github.com` and `[markdown][link]`.
 */
const standardStyle = createDecoPlugin(() => {
  const matcher = new MatchDecorator({
    // Fragile approach, but we only use it for link clicking, it should be fine
    regexp: regexp.standard,
    boundary: /\S/,
    decorate: (add, from, to, match) => {
      const spec = createSpec();
      const deco = Decoration.mark(spec);

      if (match[4]) {
        // Markdown links, only decorate the part inside parentheses
        add(from + match[4].length, to - 1, deco);
      } else {
        // Normal links, decorate the full match
        add(from, to, deco);
      }
    },
  });

  return matcher.createDeco(window.editor);
});

/**
 * For `[^footnote]` and `[reference][link]`.
 */
const referenceStyle = createDecoPlugin(() => {
  return createDecos('Link', ({ from, to }) => {
    const content = window.editor.state.sliceDoc(from, to);
    const newDeco = (type: 'Link' | 'LinkLabel', label: string) => Decoration.mark(createSpec({
      'data-link-type': type,
      'data-link-from': `${from}`,
      'data-link-to': `${to}`,
      'data-link-label': label,
    })).range(from, to);

    // [^footnote]
    const footnote = content.match(regexp.footnote);
    if (footnote !== null) {
      // Looking for the entire link
      return newDeco('Link', footnote[0]);
    }

    // [reference][link]
    const reference = content.match(regexp.reference);
    if (reference !== null) {
      // Looking for the label only
      return newDeco('LinkLabel', `[${reference[1]}]`);
    }

    return null;
  });
});

export const linkStyles: Extension = [
  standardStyle,
  referenceStyle,
];

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

  linkElement.title = window.config.localizable?.cmdClickToFollow ?? '';
  linkElement.style.cursor = '';
  linkElement.style.textDecoration = '';
  linkElement.style.textDecorationColor = '';
}

export function handleMouseDown(event: MouseEvent) {
  if (extractLink(event.target).link !== undefined) {
    event.stopPropagation();
    event.preventDefault();
  }
}

export function handleMouseUp(event: MouseEvent) {
  const { link, element } = extractLink(event.target);
  if (link === undefined) {
    return;
  }

  // [^footnote] or [reference][link]
  const type = element.getAttribute('data-link-type');
  if (type !== null) {
    return followReference(element, type);
  }

  // [standard][link] or <standard-link>
  if (isReleaseMode) {
    window.nativeModules.core.notifyLinkClicked({ link });
  } else {
    // Test only branch
    window.open(link, '_blank');
  }
}

function extractLink(target: EventTarget | null) {
  const selector = `.${className}`;
  const element = (target as HTMLElement | null)?.closest<HTMLElement>(selector);

  // The element doesn't belong to a Markdown link
  if (element === null || element === undefined) {
    return {};
  }

  // The link is clickable when it has an underline,
  // use includes because Chrome merges textDecorationColor into textDecoration.
  if (!element.style.textDecoration.includes('underline')) {
    return {};
  }

  // It's OK to have a trailing period in a valid url,
  // but generally it's the end of a sentence and we want to remove the period.
  const link = element.innerText;
  if (link.endsWith('.') === true && link.endsWith('..') !== true) {
    return { element, link: link.slice(0, -1) };
  }

  return { element, link };
}

function createSpec(attributes?: { [key: string]: string }) {
  return {
    class: className,
    attributes: {
      title: window.config.localizable?.cmdClickToFollow ?? '',
      onmouseenter: '_startLinkClickable(this)',
      onmouseleave: '_stopLinkClickable(this)',
      ...attributes,
    },
  };
};

function followReference(element: HTMLElement, type: string) {
  const state = window.editor.state;
  const from = parseInt(element.getAttribute('data-link-from') ?? '0');
  const to = parseInt(element.getAttribute('data-link-to') ?? '0');
  const label = element.getAttribute('data-link-label') ?? '';
  const isDefinition = (pos: number) => state.sliceDoc(pos, pos + 1) === ':';

  return scrollIntoTarget(getNodesNamed(state, type).find(node => {
    if (node.to >= from && node.from <= to) {
      return false;
    }

    if (state.sliceDoc(node.from, node.to) !== label) {
      return false;
    }

    // For [^footnote], if definition is cmd-clicked, goto the first reference
    if (type === 'Link') {
      return isDefinition(to) ? true : isDefinition(node.to);
    }

    // For [reference][link], always goto the definition
    return isDefinition(node.to);
  }));
}

function scrollIntoTarget(target?: SyntaxNodeRef) {
  if (target === undefined) {
    return window.nativeModules.core.notifyLightWarning();
  }

  window.editor.dispatch({
    selection: EditorSelection.range(target.from, target.to),
    effects: EditorView.scrollIntoView(target.from, { y: 'center' }),
  });
}

const storage: {
  focusedElement: HTMLElement | undefined;
} = {
  focusedElement: undefined,
};
