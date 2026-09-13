# Reference terrain workbench

The AoNW Map dock now opens the reference reconstruction workflow by default.
It combines canonical JSON heights and terrain tags, verified compiled height
rasters, and the matching reference atlas. Existing canonical authoring scenes
and earlier reconstruction drafts are not overwritten.

## Start in the panel

1. Restart the Godot editor after updating the plugin scripts. Enable the existing
   Terrain3D and AoNW Map Workbench plugins if they are disabled.
2. Select a map in **AoNW Map**. Selection and **Generate / open landscape** use
   the same scene factory and source catalog. The Terrain3D tab opens by default.
3. Adjust the landscape controls and press **Apply / rebuild landscape**.
   Appearance, reference/grid opacity, lighting and strategic camera controls
   apply immediately; geometry controls are intentionally staged.
4. Inspect the live strategic preview in the panel, or run the map scene with F6.
5. Use **Save terrain + recipe + mask** to save native Terrain3D sculpt data,
   the recipe, water mask, and applied scene settings.

The supplied scenes are under `res://scenes/terrain_authoring/reference_maps/`:
`dravonia`, `myranth`, `terenos`, `verdantia`, and `aonw2_starter`. New maps use
that same factory rather than copying a Dravonia-specific script. The source
picker and reconstruction resolve the same canonical document. Cached compiled
artifacts take precedence over packaged ones only when the cache exists. Stale
hashes, corrupt atlases and inconsistent dimensions fail explicitly; a different
map or outdated reference is not silently substituted.

Missing reference atlases are supported as a clearly reported **semantic-only**
mode. In that mode JSON water tags, height levels and biome tags drive the
landscape, with no image-refinement claim. Reference-only controls are disabled.

## Controls and their effects

The versioned `reference_terrain_parameters.gd` schema defines UI ranges, defaults,
validation, stage, help and presets. There is one original metric-height control
and twenty additional range controls (the seed uses a numeric box).

| Stage | Parameters | Application |
| --- | --- | --- |
| Terrain | JSON level-5 height, mountain relief, rolling hills, reference influence, ridge sharpness, cross-hex continuity, detail strength and wavelength, bank width, relaxation passes, seed | Staged; explicit rebuild |
| Material/light | Relief lighting, rock slope threshold, sun elevation and heading, direct and ambient intensity | Live, no height rebuild |
| Camera | Pitch, heading, dolly zoom, field of view | Live perspective preview |
| Existing overlays | Reference enable/blend, grid enable/opacity, constraint envelopes, city marker and coordinates | Live |

The height control now sets the **presentation** scale. It does not write a
canonical terrain profile and then call the old hex-constrained rescale path.
A high JSON level or mountain tag locates a range; it does not create one cone
per hex. Smoothed compiled elevation and direct JSON levels jointly form the
macro envelope. Smoothed mountain/hill masks control local relief. Multiscale
reference contrast or an explicit ridge guide shapes crests inside that envelope;
seeded world-space noise supplies secondary detail. Hills and lowlands receive
smaller relief. Water samples are locked to zero in base/min/max after relaxation.

Presets: **Reference faithful**, **Strategic natural**, **Rugged**. Presets stage
geometry without throwing away a sculpt or changing the camera. Discard removes
pending numeric settings. Applied parameters are stored in the scene; un-applied
settings are not falsely recorded as the current terrain recipe.

## Reference, material and camera

Reference opacity is an opaque blend between the illustration and a procedural
biome/rock material on the draped geometry. Zero, or disabling the reference,
reveals the material; it does not hide all ground or leave an alpha-depth sheet.
The active ShaderMaterial receives the value, rather than only its unused base
StandardMaterial. Terrain tags provide biome colours and slope provides rock
coverage. These are authoring materials, not a complete production PBR asset set.

**Strategic** selects a perspective camera with configurable pitch, FOV, rotation
and real camera-distance zoom. **Reference top** gives an unlit orthographic
comparison. The dock preview shares the edited world without replacing Godot's
editor-navigation camera. In the preview: right drag orbits; middle/Shift-right
pans; wheel/magnify dollies. In F6, `1` is reference top, `2` strategic, `R` toggles
reference/material and `G` toggles the grid. The sun and environment are local to
each map scene, so changing one scene's ambient light does not edit another's.

Use the strategic camera to evaluate silhouette, depth and readability. This is
not a reproduction of Civilization VI's art, lighting pipeline or assets, nor a
promise that automatic reconstruction will look photorealistic.

## Precise guidance

Assign optional lossless grayscale **Water Guide** and **Ridge Guide** textures
to the root in the Inspector, then Apply in the dock (or its Inspector rebuild
button). Guides must match the assembled reference-atlas pixel dimensions and
use the same UV transform. White water is locked to zero; black is land. The
water guide replaces automatic hydrology. White ridge is a crest, black a valley
inside the elevation envelope. Reference influence 1 follows explicit ridges.

The reference is an illustration, not a DEM. Painted shadows, pale snow, brown
rivers and sub-sample features can be ambiguous. The automatic water detector
uses chroma and semantic connectivity, not brightness alone, but manual guides
may still be necessary. Zero-height rivers deliberately follow the requested
future-water convention, not physically graded riverbeds. No water shader or
hydraulic-flow simulation is introduced by this branch.

## Session safety and legacy boundaries

A map uses one self-opening reference session. The plugin waits for it before
synchronizing controls, and later state changes resynchronize the dock without
emitting slider edits. Controls cannot target a different map than the selected
one. Canonical and reference sessions never compete to initialize the same data.

A rebuild computes and validates its inputs before replacing native regions.
The previous draft is saved first. Its `maps_edited` callback is disconnected,
so its old constraints cannot flatten the next recipe. A failed target open
attempts to restore the previous saved session. The dock resets **this scene's**
undo history after a recipe switch: old brush actions must not operate on new
regions. Other scene histories are not cleared.

Each geometry recipe uses:

```text
res://assets/generated_maps/<map>/reference_terrain/<workspace-key>/
```

Identity includes algorithm/schema/Godot versions, map/profile/source hashes,
reference and guides, geometry options and output heights. Material and camera
changes do not create new geometry workspaces. Reopening the same recipe restores
its native sculpt. Earlier `natural_relief`, `terrain_authoring` and v1 recipe
folders remain untouched. The `water_mask.png` companion is **terrain-raster**
sized, not an atlas-sized input guide. Pixel `(x,y)` maps to terrain local
`(x * sampleSpacingMeters, 0, y * sampleSpacingMeters)`.

Runtime publish is hidden on reference scenes because they do not yet implement
the game's canonical publication contract. Canonical logical painting is disabled
there rather than persisting JSON and failing midway through a reference refresh.
To change gameplay tiles, use the legacy canonical scene/workbench or source
content tools, recompile the inputs and update matching atlas identity, then
rebuild the reference scene. Legacy scenes retain their original editing path.
Generated decoration placement and production runtime integration are separate
from this landscape authoring system.

## Extending the system

Keep pixel algorithms in the pure builder/landscape fields, source validation in
`reference_terrain_inputs`, native lifecycle in `reference_terrain_session`, and
editor bindings in the dock. To add a parameter, add its schema entry, implement
its stage's effect, and extend the sensitivity or presentation tests. Increment
the generator version when geometry semantics change. Do not put gameplay rules
in the material or dock. Biome material selection, erosion passes and guided
hydrology can be extended behind these boundaries without adding per-map code.

## Validation

Pure raster, parameter/UI-signal and camera contracts can run in an isolated
project with the exact dependency scripts and no gameplay native extension:

```sh
python3 clients/aonw_godot/tool/run_reference_contracts.py \
  --godot /Applications/Godot.app/Contents/MacOS/Godot
```

The branch workflow runs those contracts on official Godot 4.6 as an API baseline
and parses the new GDScript. This is not full native/editor/GPU acceptance for the
project's configured Godot version. Check the actual Actions result; adding tests
is not evidence that they have passed.

In the fully imported project, with its matching Engine and Terrain3D libraries:

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path clients/aonw_godot --script res://tests/test_reference_native_controls.gd
"$GODOT" --headless --path clients/aonw_godot --script res://tests/test_reference_terrain_maps.gd
```

The native control test writes only a unique `user://reference-tests` directory.
It checks active reference/grid materials, overlays, live appearance, pending
geometry, session detachment, native water samples and saving. The all-map test
discovers bundles. Adding `-- --save` to the all-map test explicitly saves default
recipes; without it, drafts are not saved. Tests of controls and sampled water
heights are not a substitute for viewing every map at strategic and close zoom.

The implementation environment did not have a local Godot executable or GPU
rendering. Native full-project tests and visual acceptance must not be inferred
from the Python runner's syntax check or from the isolated baseline workflow.
