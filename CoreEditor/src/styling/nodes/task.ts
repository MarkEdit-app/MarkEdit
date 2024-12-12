import { Decoration } from '@codemirror/view';
import { Line } from '@codemirror/state';
import { createDecos } from '../matchers/lezer';
import { createDecoPlugin } from '../helper';
import { setTaskMarkerStyle } from '../config';

const className = 'cm-md-taskMarker';

export const taskMarkerStyle = createDecoPlugin(() => {
  return createDecos('TaskMarker', ({ from, to }) => Decoration.mark({
    attributes: {
      class: className,
      title: window.config.localizable?.cmdClickToToggleTodo ?? '',
    },
  }).range(lineAt(from).from, to));
});

export function startClickable() {
  setTaskMarkerStyle(true);
}

export function stopClickable() {
  setTaskMarkerStyle(false);
}

export function handleMouseDown(event: MouseEvent) {
  const element = event.target as HTMLElement | null;
  const marker = element?.closest(`.${className}`);
  if (marker === null || marker === undefined) {
    return;
  }

  const editor = window.editor;
  const selection = editor.state.selection;
  const line = lineAt(editor.posAtDOM(marker));

  const toggled = (() => {
    const text = line.text;
    if (text.match(/^( *- +\[[ ]\] +)/) === null) {
      // - [x] to - [ ]
      return text.replace(/(- +\[)[xX](\].*)/, '$1 $2');
    } else {
      // - [ ] to - [x]
      return text.replace(/(- +\[) (\].*)/, '$1x$2');
    }
  })();

  editor.dispatch({
    changes: {
      from: line.from,
      to: line.to,
      insert: toggled,
    },
    selection, // Preserve selections
    userEvent: '@none', // Ignore automatic scrolling
  });

  event.preventDefault();
  event.stopPropagation();
}

function lineAt(pos: number): Line {
  return window.editor.state.doc.lineAt(pos);
}
