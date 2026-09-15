# Private Hotseat handoff

The handoff follows the reference's centered 72 px civilization-colored avatar,
player name, turn and prominent continuation action. It retains an opaque privacy
barrier and adds the localized device-transfer instruction. Identity comes from
the canonical roster; the turn is shown only after the recipient has switched.
The initial uses one Unicode grapheme. Name, instructions and action honor text
scaling; the decorative avatar stays fixed. Content scrolls inside the safe area.

The handoff owns a modal gamepad region above ordinary panels and popups. Only a
fresh activation confirms; B/Escape, gameplay actions and camera axes cannot
reveal or manipulate the map. Ownership changes prime held buttons. The action
autofocuses for keyboard use, while the underlying map loses traversal, semantics
and tooltips. The latter also removes tooltip portals outside the normal stack.
Switching disables confirmation; failure retains the barrier and offers retry.

Validation:

- 32 focused widget tests passed: pointer/retry, keyboard, six languages at 200%
  in both phone orientations, normalized controller input, camera isolation,
  held-button transitions, accessibility isolation, and existing HUD navigation.
- Four reviewed goldens: PL phone, DE tablet, EN desktop, and DE phone at 200%.
  Fonts and icon assets are loaded; all four idle screens have no animations.
- Dart analyzer and unchanged architecture budgets passed.

Normalized events verify application routing, not a physical controller driver.
Native Hotseat/privacy validation remains part of the final device gate.
