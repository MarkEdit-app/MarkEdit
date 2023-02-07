import { Decoration, EditorView } from '@codemirror/view';
import { Compartment, StateField, StateEffect, RangeSet } from '@codemirror/state';

/**
 * Start stateful effects with compartment.
 *
 * @param compartment Compartment
 * @param ranges Range set of decorations
 */
export function startEffect(compartment: Compartment, ranges: RangeSet<Decoration>) {
  const extension = StateField.define({
    create() { return Decoration.none; },
    update() { return ranges; },
    provide: field => EditorView.decorations.from(field),
  });

  const effect = StateEffect.appendConfig.of(compartment.of(extension));
  window.editor.dispatch({ effects: [effect] });
}

/**
 * Stop stateful effects captured in compartments.
 *
 * @param compartments Compartments
 */
export function stopEffect(compartments: Compartment[]) {
  for (const compartment of compartments) {
    const extension = StateField.define({ create() { /* no-op */ }, update() { /* no-op */ } });
    const effects = compartment.reconfigure(extension);
    window.editor.dispatch({ effects });
  }
}
