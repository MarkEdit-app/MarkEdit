// Substantially rewritten from https://github.com/laurent22/joplin/blob/dev/packages/editor/CodeMirror/extensions/markdownMathExtension.ts

import { StreamLanguage } from '@codemirror/language';
import { stexMath } from '@codemirror/legacy-modes/mode/stex';
import { Input, NodeProp, ParseWrapper, Tree, TreeFragment, parseMixed } from '@lezer/common';
import { tags, Tag } from '@lezer/highlight';
import { BlockContext, Element, Line, MarkdownConfig, MarkdownParser } from '@lezer/markdown';

const texLanguage = StreamLanguage.define(stexMath);
export const blockMathTagName = 'BlockMath';
export const blockMathContentTagName = 'BlockMathContent';
export const mathTag = Tag.define(tags.monospace);

const firstMathStart = new NodeProp<{ start: number; parser: MarkdownParser }>({ perNode: true });
let activeParse: MathParseState | undefined;

interface MathParseState {
  rejected: Set<number>;
  firstStart: number;
  parser?: MarkdownParser;
  restart: MarkdownParser | undefined;
}

class MathInput implements Input {
  constructor(readonly input: Input, readonly ranges: readonly { from: number; to: number }[]) {}
  get length() { return this.input.length; }
  get lineChunks() { return this.input.lineChunks; }
  chunk(from: number) { return this.input.chunk(from); }
  read(from: number, to: number) { return this.input.read(from, to); }
}

const parseTeX = parseMixed(node => {
  if (node.name !== blockMathTagName) {
    return null;
  }

  const overlay = node.node.getChildren(blockMathContentTagName).map(({ from, to }) => ({ from, to }));
  return overlay.length ? { parser: texLanguage.parser, overlay } : null;
});

const wrapMath: ParseWrapper = (inner, input, fragments, ranges) => {
  if (input instanceof MathInput && input.ranges === ranges) {
    return inner;
  }

  const state: MathParseState = { rejected: new Set(), firstStart: Infinity, restart: undefined };
  const retryInput = new MathInput(input, ranges);
  let parse = inner;
  let initialized = false;

  return parseTeX({
    advance() {
      const previous = activeParse;
      activeParse = state;
      try {
        if (!initialized) {
          initialized = true;
          const reusable = fragments.flatMap(fragment => {
            const dependency = fragment.tree.prop(firstMathStart);
            if (dependency === undefined) {
              return [fragment];
            }

            const to = Math.min(fragment.to, dependency.start - fragment.offset);
            return to > fragment.from
              ? [new TreeFragment(fragment.from, to, fragment.tree, fragment.offset, fragment.openStart, true)]
              : [];
          });

          const dependency = fragments.map(fragment => fragment.tree.prop(firstMathStart)).find(value => value !== undefined);
          if (dependency) {
            const stoppedAt = parse.stoppedAt;
            parse = dependency.parser.createParse(retryInput, reusable, ranges);
            if (stoppedAt !== null) {
              parse.stopAt(stoppedAt);
            }
          }
        }

        const tree = parse.advance();
        if (tree && state.restart) {
          const stoppedAt = parse.stoppedAt;
          parse = state.restart.createParse(retryInput, [], ranges);
          state.restart = undefined;
          if (stoppedAt !== null) {
            parse.stopAt(stoppedAt);
          }

          return null;
        }

        return tree && state.parser && Number.isFinite(state.firstStart)
          ? new Tree(tree.type, tree.children, tree.positions, tree.length,
            [...tree.propValues, [firstMathStart, { start: state.firstStart - ranges[0].from, parser: state.parser }]])
          : tree;
      } finally {
        activeParse = previous;
      }
    },
    get parsedPos() { return parse.parsedPos; },
    get stoppedAt() { return parse.stoppedAt; },
    stopAt(pos) { parse.stopAt(pos); },
  }, input, fragments, ranges);
};

function startsMath(cx: BlockContext, line: Line) {
  if (!line.text.startsWith('$$', line.pos)) {
    return false;
  }

  const start = cx.lineStart + line.pos;
  if (activeParse) {
    activeParse.parser = cx.parser;
  }

  return activeParse?.rejected.has(start) !== true;
}

function closingDelimiter(text: string, from: number) {
  const match = /\$\$[ \t\r]*$/.exec(text);
  if (!match || match.index < from) {
    return -1;
  }

  let backslashes = 0;
  for (let pos = match.index - 1; pos >= from && text[pos] === '\\'; pos--) {
    backslashes++;
  }

  return backslashes % 2 ? -1 : match.index;
}

/**
 * Markdown block math with required closing delimiters.
 */
export const markdownMathExtension: MarkdownConfig = {
  defineNodes: [
    { name: blockMathTagName, block: true, style: mathTag },
    { name: blockMathContentTagName },
  ],
  parseBlock: [{
    name: blockMathTagName,
    after: 'Blockquote',
    parse(cx, line) {
      if (!startsMath(cx, line)) {
        return false;
      }

      const start = cx.lineStart + line.pos;
      const depth = cx.depth;
      const content: { from: number; to: number }[] = [];
      const markers: Element[] = [];
      const candidates = [start];
      let contentFrom = line.pos + 2;

      for (;;) {
        const end = closingDelimiter(line.text, contentFrom);
        const from = cx.lineStart + contentFrom;
        const to = cx.lineStart + (end < 0 ? line.text.length + 1 : end);
        if (to > from) {
          const last = content[content.length - 1] as (typeof content)[number] | undefined;
          if (last?.to === from) {
            last.to = to;
          } else {
            content.push({ from, to });
          }
        }

        if (end >= 0) {
          const children = [...markers, ...content.map(range => cx.elt(blockMathContentTagName, range.from, range.to))];
          children.sort((left, right) => left.from - right.from);
          cx.addElement(cx.elt(blockMathTagName, start, cx.lineStart + end + 2, children));
          cx.nextLine();
          return true;
        }

        if (!cx.nextLine() || (line as Line & { depth: number }).depth < depth) {
          break;
        }

        markers.push(...line.markers);
        contentFrom = line.basePos;
        if (line.text.startsWith('$$', line.pos)) {
          candidates.push(cx.lineStart + line.pos);
        }
      }

      if (activeParse) {
        activeParse.firstStart = Math.min(activeParse.firstStart, start);
        for (const candidate of candidates) {
          activeParse.rejected.add(candidate);
        }

        activeParse.restart = cx.parser;
      }
      return true;
    },
    endLeaf: startsMath,
  }],
  wrap: wrapMath,
};
