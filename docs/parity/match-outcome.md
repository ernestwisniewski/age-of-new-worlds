# Match outcome presentation

The shared map presents the accepted Rust `GameOutcomeView` in a modal summary.
Winner identity selects the recipient's victory/defeat treatment; no winner uses
the draw treatment. The UI never runs a victory detector or infers the winner from
scores. Public roster names replace raw IDs. Final scores sort by their received
value, then player ID, and bars only scale their visual lengths.

The reference's compact 460 px panel, colored icon/border, metric bars and return
button are retained. Domination details use the disclosed controlled/total hexes,
hold count and configured threshold. Cultural details are displayed only when the
winner is the current recipient; a rival's collection is not read or reconstructed.

The application router returns directly to the main menu and clears the completed
map route. Pointer, Enter, gamepad activation and B/Escape share that action and
its navigation sound. The underlying map loses focus, semantics and tooltips;
continuous camera input and gameplay commands are captured. Replay keeps the
terminal map inspectable without the blocking outcome modal.

Validation:

- 62 focused widget/router tests passed, including six languages at 200% in both
  phone orientations, explicit winner/tone and cultural privacy checks, keyboard,
  pointer/gamepad return to the menu, camera isolation and existing handoff/HUD.
- Replay presentation/controller regressions passed in the navigation run. That
  run's original generic-outcome semantics assertion was repaired by retaining
  a separate live-region container; the final focused run passed it.
- Four reviewed goldens: PL victory phone, DE defeat tablet, EN draw desktop and
  DE defeat phone at 200%; no idle animations.
- Analyzer and generated-code synchronization passed. Architecture removes one
  obsolete long-method allowance without increasing any limit.

Device end-to-end checks and the remaining HUD families are still part of M9/M7.
