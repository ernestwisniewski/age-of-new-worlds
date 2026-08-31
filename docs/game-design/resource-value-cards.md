# Resource value cards

A resource card explains what a selected hex provides now, how it can be improved, what later rules use it, and why it may be worth claiming.

The card belongs to map inspection rather than a separate global screen. A hex with resources exposes the card from its inspection panel and compact long-press view.

## Data

| Section | Source |
| --- | --- |
| Category and name | `ResourceCatalog` and localized display names |
| Current tile value | shared hex/city yield assessment |
| Legal improvement | field-improvement rules and technology unlock query |
| Future use | technology requirements, boosts, effects, production/trade roles |
| Expansion note | resource economy mode and dominant improved value |

The card has no private yield or unlock table. Changes to the active ruleset, technology catalog, or improvement catalog must appear automatically.

Improvement status distinguishes missing technology, territory/city blockers, an existing improvement, and a legal current action. The long-press view uses the same legality model and color coding.

Bonus, luxury, presence-gated strategic, and stockpiled strategic resources have different player roles; read the mode from `ResourceCatalog`, not from enum names or a UI-maintained list.

This feature explains current balance. It does not create new objectives, happiness rules, AI scoring, or resource-specific worker automation.
