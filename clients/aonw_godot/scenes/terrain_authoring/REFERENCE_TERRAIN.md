# Reference-guided terrain authoring

The `feature/maps-terrain` work starts from main at `9b4104112749` and reuses
Dravonia's raster kernels, preview camera and relief shader. It does not merge
an old game/client snapshot or replace the existing Terenos/Myranth scenes.

## Open a map

Open any scene under `res://scenes/terrain_authoring/reference_maps/`:
`dravonia.tscn`, `myranth.tscn`, `terenos.tscn`, `verdantia.tscn`, or
`aonw2_starter.tscn`. The shared implementation builds native Terrain3D height
regions on scene open. F6 runs the same scene with an orbit/pan camera.

On macOS, from the repository root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path clients/aonw_godot \
  res://scenes/terrain_authoring/reference_maps/dravonia.tscn
```

Use the project's Godot/Terrain3D versions and import the project first, as for
the original authoring workflow. No Rust gameplay changes are required.
Fresh `res://.godot/terrain_compiled/<map>/` artifacts take precedence over the
packaged `res://assets/terrain_compiled/<map>/` data. Invalid/stale identities or
atlas hashes fail explicitly; another map is never silently substituted.

The generic `reference_terrain.tscn` accepts any complete map bundle through
`Source Map Id` and `Map Bundle Root`. Add new bundles without copying generator
code. Change settings, save the scene, then close/reopen it to build that recipe.

## What determines the shape

* Compiled metre heights provide the broad elevation envelope. Cross-hex
  smoothing removes isolated hexagonal plateaus. The canonical map JSON and
  its min/max images are not edited.
* Multi-scale image contrast locates reference crests and valleys inside that
  envelope. It shapes the mountain geometry itself. Continuous ridged noise
  supplies detail/fallback where the illustration contains little information.
  Hills and lowlands receive smaller, smoother relief.
* Blue/cyan image regions connected to semantic water seeds define sub-hex
  coastlines, lakes and rivers. Snow/forest are not classified by brightness
  alone. Ambiguous water at source sea level is retained conservatively and
  counted in the console report. An all-water source stays all water.
* A distance-to-water field forms banks. Masked samples are exactly **0 metres**
  after every operation; their minimum and maximum are also zero, so ordinary
  Terrain3D brush edits cannot raise them. Talus relaxation only moves material
  between unprotected land samples.

This is image-guided procedural reconstruction, **not** exact recovery of a
3D surface from an illustration, semantic image recognition, or a hydraulic
simulation. Painted lighting, dark rock, non-blue rivers and features thinner
than the height raster can be ambiguous. Zero-height rivers are deliberately a
future-water authoring convention; they are not physically graded riverbeds.
Inspect every map in both reference and clay modes before accepting its look.
Do not treat passing numerical tests as visual approval.

## Precise artistic control

The Inspector exposes `Mountain Height Scale`, `Reference Influence`, and a
seed. For difficult references, assign lossless, atlas-sized grayscale textures
to `Water Guide` and/or `Ridge Guide`:

* Water: white = exactly zero; black = land. This **replaces** colour-derived
  hydrology rather than unioning it with old hex polygons.
* Ridges: white = crest; black = valley, inside the logical height envelope.
  Explicit guidance overrides uncertain image contrast. Use `Reference Influence
  = 1` to follow it fully.

Guides must have exactly the assembled reference-atlas dimensions. They use the
same world-to-reference UV mapping as the draped texture, including the padded
last row; no independent stretching or axis flip is introduced. Leave a guide
unassigned to use automatic reconstruction. The exported water mask below is
terrain-raster-sized and is **not** an atlas-sized input guide.

`1` gives an unlit top/reference view; `2` shaded oblique; `R` toggles reference
and clay; `G` the hex grid; `L` lighting. Right-drag orbits, middle/Shift-right-drag
pans, and the wheel zooms.

## Save and regenerate safely

Use **Save terrain draft and water mask** on the root node. Each recipe lives in:

```text
res://assets/generated_maps/<map>/reference_terrain/<workspace-key>/
```

The existing persistence layer saves editable native Terrain3D regions. Alongside
the draft, `water_mask.png` (white water, black land) and `reference_recipe.json`
are written for later water authoring. Mask pixel `(x,y)` corresponds to terrain
local `(x * sampleSpacingMeters, 0, y * sampleSpacingMeters)`.

The workspace key includes source/profile/map identity, reference pixels,
guidance, algorithm/Godot version, seed, settings, and the actual output height
hash. Reopening the same recipe restores its draft instead of accumulating
noise; changing the recipe uses a new directory. Existing `terrain_authoring`,
`natural_relief`, and manually authored scene files are not reset or overwritten.
Do not commit generated region caches unless intentionally publishing art.

This remains a **presentation authoring** workflow, matching the Dravonia study.
Runtime publishing and generic canonical refresh/rescale actions are blocked on
these surfaces so they cannot replace the continuous relief with hex constraints.
The regular map workbench and its existing scenes keep their original behavior.
This branch does not add a water shader or change Rust/Flutter gameplay rules.

## Validation and optional batch generation

After importing the project, run from the repository root:

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path clients/aonw_godot --script res://tests/test_natural_relief.gd
"$GODOT" --headless --path clients/aonw_godot --script res://tests/test_reference_terrain.gd
"$GODOT" --headless --path clients/aonw_godot --script res://tests/test_reference_terrain_maps.gd
```

The pure-raster suite checks determinism, source immutability, image/guide
influence, exact water locks after relaxation, envelopes, map-coordinate
validation and hydrology. The native smoke test discovers **all** map bundles,
loads them separately, verifies map identity and samples actual Terrain3D water
heights. Without flags it does not save drafts. It returns a nonzero exit status
on a failure, including missing references or compiled artifacts.

To generate **and save** the default reconstruction for every map:

```sh
"$GODOT" --headless --path clients/aonw_godot \
  --script res://tests/test_reference_terrain_maps.gd -- --save
```

The batch uses default settings, not per-scene Inspector overrides. Save a
custom-guided version through its scene. Generation is bounded by the inherited
4,194,304-sample budget and runs synchronously as an offline authoring operation,
not in the gameplay frame loop.

Validation status when this change was authored: native Godot/Terrain3D execution
and visual renders were unavailable in the editing environment. The suites above
are provided but must be run in the project environment; no visual acceptance or
successful native test run is implied.
