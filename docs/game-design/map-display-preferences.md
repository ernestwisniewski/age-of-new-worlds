# Map display preferences

Border and height-wall colors are presentation preferences. They are not map content or save state.

`HexDisplaySettings` carries:

| Field | Effect |
| --- | --- |
| `hexBorderColor` | Top-face hex outline. Alpha 0 disables the outline. |
| `wallTintColor` | Base tint for height walls. |

The renderer assigns each shared edge one owner and avoids drawing a lower edge hidden by a higher neighbor. This prevents doubled translucent lines and panning flicker.

The map editor stores global defaults in `SharedPreferences`:

- `hex_display.default.hex_border_color`
- `hex_display.default.wall_tint_color`

The game may store a per-map override keyed by map source and name. Choosing **Default** removes that override and returns to the editor-defined global value.

Do not write these colors into authored map JSON or canonical gameplay state.
