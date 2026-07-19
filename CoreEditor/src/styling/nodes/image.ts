import { EditorState } from '@codemirror/state';
import { SyntaxNodeRef } from '@lezer/common';
import { getSyntaxTree } from '../../modules/lezer';
import { tryGetEditor } from '../../common/utils';
import { createDecoPlugin } from '../helper';
import { createWidgetDeco } from '../matchers/lezer';
import { WidgetView } from '../views/types';

const imageLoaderScheme = 'image-loader';

type ImageInfo = {
  alt: string;
  destination: string;
  title?: string;
};

/**
 * Show an image directly after its Markdown source while keeping the source editable.
 */
export const imagePreviewStyle = createDecoPlugin(() => {
  const state = window.editor.state;
  let references: Map<string, string> | undefined;

  return createWidgetDeco('Image', node => {
    const info = imageInfo(node, state, () => {
      references ??= referenceDestinations(state);
      return references;
    });
    if (info === null) {
      return null;
    }

    const source = imageSource(info.destination);
    if (source.length === 0) {
      return null;
    }

    return new ImagePreviewWidget(
      source,
      info.alt,
      info.title,
      node.to,
    );
  });
});

/**
 * Use the native scheme handler for local files so relative paths resolve against
 * the open document. Web resources can be loaded by WebKit as-is.
 */
export function imageSource(destination: string) {
  const value = normalizeDestination(destination);
  if (value.length === 0) {
    return '';
  }

  if (value.startsWith('//')) {
    return value;
  }

  if (value.startsWith('/')) {
    return '';
  }

  const scheme = /^([a-z][a-z\d+.-]*):/i.exec(value)?.[1].toLowerCase();
  if (scheme !== undefined) {
    return ['http', 'https', 'data', 'blob', imageLoaderScheme].includes(scheme) ? value : '';
  }

  return `${imageLoaderScheme}://${encodeImagePath(value)}`;
}

export class ImagePreviewWidget extends WidgetView {
  constructor(
    private readonly source: string,
    private readonly alt: string,
    private readonly title: string | undefined,
    pos: number,
  ) {
    super();
    this.pos = pos;
  }

  toDOM() {
    const wrapper = document.createElement('span');
    wrapper.className = 'cm-md-imagePreview';
    wrapper.hidden = true;

    const image = wrapper.appendChild(document.createElement('img'));
    image.className = 'cm-md-imagePreviewImage';
    image.src = this.source;
    image.alt = this.alt;
    image.draggable = false;
    image.decoding = 'async';

    if (this.title !== undefined) {
      image.title = this.title;
    }

    image.addEventListener('load', () => {
      wrapper.hidden = false;
      tryGetEditor()?.requestMeasure();
    });

    // The Markdown source remains visible, so a missing image needs no extra
    // broken-image placeholder in the editor.
    image.addEventListener('error', () => {
      wrapper.hidden = true;
      tryGetEditor()?.requestMeasure();
    });

    return wrapper;
  }

  eq(other: ImagePreviewWidget) {
    return other.source === this.source
      && other.alt === this.alt
      && other.title === this.title
      && other.pos === this.pos;
  }

  ignoreEvent() {
    return true;
  }
}

function imageInfo(
  node: SyntaxNodeRef,
  state: EditorState,
  getReferences: () => Map<string, string>,
): ImageInfo | null {
  const marks = node.node.getChildren('LinkMark');
  const closingAltMark = marks.find(mark => state.sliceDoc(mark.from, mark.to) === ']');
  if (closingAltMark === undefined) {
    return null;
  }

  const alt = unescapeMarkdown(state.sliceDoc(node.from + 2, closingAltMark.from));
  const urlNode = node.node.getChild('URL');
  const destination = urlNode === null
    ? getReferences().get(referenceLabel(node, state, alt))
    : state.sliceDoc(urlNode.from, urlNode.to);

  if (destination === undefined || destination.length === 0) {
    return null;
  }

  const titleNode = node.node.getChild('LinkTitle');
  const title = titleNode === null
    ? undefined
    : unescapeMarkdown(stripTitleMarks(state.sliceDoc(titleNode.from, titleNode.to)));

  return { alt, destination, title };
}

function referenceDestinations(state: EditorState) {
  const references = new Map<string, string>();

  getSyntaxTree(state).iterate({
    from: 0,
    to: state.doc.length,
    enter: node => {
      if (node.name === 'LinkDefinition') {
        const label = node.node.getChild('LinkDefinitionID');
        const line = state.doc.lineAt(node.to);
        const match = state.sliceDoc(node.to, line.to).match(/^:\s*(?:<([^>]+)>|(\S+))/);
        const destination = match?.[1] ?? match?.[2];
        if (label !== null && destination !== undefined) {
          addReference(references, state.sliceDoc(label.from, label.to), destination);
        }
        return;
      }

      if (node.name !== 'LinkReference') {
        return;
      }

      const label = node.node.getChild('LinkLabel');
      const url = node.node.getChild('URL');
      if (label === null || url === null) {
        return;
      }

      addReference(
        references,
        state.sliceDoc(label.from + 1, label.to - 1),
        state.sliceDoc(url.from, url.to),
      );
    },
  });

  return references;
}

function addReference(references: Map<string, string>, label: string, destination: string) {
  const key = normalizeReferenceLabel(label);
  if (!references.has(key)) {
    references.set(key, destination);
  }
}

function referenceLabel(node: SyntaxNodeRef, state: EditorState, alt: string) {
  const labelNode = node.node.getChild('LinkLabel');
  const label = labelNode === null
    ? alt
    : state.sliceDoc(labelNode.from + 1, labelNode.to - 1) || alt;

  return normalizeReferenceLabel(label);
}

function normalizeReferenceLabel(value: string) {
  return unescapeMarkdown(value).trim().replace(/\s+/g, ' ').toLowerCase();
}

function normalizeDestination(destination: string) {
  const value = destination.startsWith('<') && destination.endsWith('>')
    ? destination.slice(1, -1)
    : destination;

  return unescapeMarkdown(value.trim());
}

function stripTitleMarks(title: string) {
  const first = title.at(0);
  const last = title.at(-1);
  if ((first === '"' && last === '"')
    || (first === '\'' && last === '\'')
    || (first === '(' && last === ')')) {
    return title.slice(1, -1);
  }

  return title;
}

function unescapeMarkdown(value: string) {
  return value.replace(/\\([!"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~])/g, '$1');
}

function encodeImagePath(value: string) {
  try {
    return encodeURIComponent(decodeURIComponent(value));
  } catch {
    // A literal percent sign isn't a valid URL escape, but it can be part of a file name.
    return encodeURIComponent(value);
  }
}
