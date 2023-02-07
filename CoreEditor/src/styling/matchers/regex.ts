import { Decoration, MatchDecorator } from '@codemirror/view';

/**
 * Create mark decorations.
 *
 * @param regexp Regular expression
 * @param builder Closure to build the decoration, or class name as a shortcut
 */
export function createMarkDeco(regexp: RegExp, builder: ((match: RegExpExecArray, pos: number) => Decoration | null) | string) {
  return createDecos(regexp, (match, pos) => {
    if (typeof builder === 'function') {
      return builder(match, pos);
    } else {
      return Decoration.mark({ class: builder });
    }
  });
}

/**
 * Build decorations by leveraging MatchDecorator.
 *
 * @param regexp Regular expression
 * @param builder Closure to create the decoration
 */
function createDecos(regexp: RegExp, builder: (match: RegExpExecArray, pos: number) => Decoration | null) {
  const matcher = new MatchDecorator({
    regexp,
    boundary: /\S/,
    decoration: (match, _, pos) => builder(match, pos),
  });

  return matcher.createDeco(window.editor);
}
