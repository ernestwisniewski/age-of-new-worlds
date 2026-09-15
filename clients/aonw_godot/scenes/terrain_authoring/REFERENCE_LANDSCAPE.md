# Reference landscape and Play preview

The `feature/maps-terrain` authoring workflow reconstructs terrain from canonical
JSON elevations/tags and the registered reference atlas, then presents PBR scans,
Tree3D meshes and a separate water surface. It does not rewrite gameplay JSON,
manual objects, movement rules or existing canonical scenes.

## Open and run

Close Godot and install visual dependencies once from the repository root:

```sh
python3 clients/aonw_godot/tool/install_reference_assets.py
```

Restart Godot. Select a map in **AoNW Terrain3D**, apply pending geometry edits,
then click **Play** in the dock or the normal **Play/F5** button. The editor
checkpoints the native draft and saves the scene before launching. Pending
geometry blocks Play with an Apply/Discard message instead of silently rendering
stale input. Selection is local to `.godot/aonw_landscape_preview.cfg`.

F5 opens `landscape_play.tscn`, with map selection, loading/error status and
Landscape / Reference / Compare / Grid buttons. The default map is Dravonia.
F6 still runs inherited `reference_maps/` scenes directly. The older gameplay
prototype remains at `res://scenes/map_preview.tscn`; the changed F5 entry point
belongs to this terrain-authoring branch.

Right drag orbits, middle/Shift-right drag pans, and wheel/pinch zooms. `1` shows
the top-down reference, `2` the lit perspective landscape, `R` compares and `G`
toggles hexes. Camera framing uses map corners and viewport aspect ratio.

## Ground and geometry

Six scanned PBR layers cover grass, forest floor, sand, snow, rock and wet soil.
Smooth semantic weights are refined by registered reference colour, brightness
and contrast. Low-frequency reference colour/value is combined with normalized
scan detail, rather than pasting the original image over 3D. Mean correction
accounts for Compatibility's sRGB shading versus Forward+'s linear space.
Normal/roughness maps and triplanar projection retain physical material detail;
only two dominant layers are sampled per fragment. Water pixels do not tint
adjacent cliffs cyan.

Native Terrain3D owns heights, editing constraints, collision and CPU picking.
Its coincident grey draw surface is hidden when the PBR surface is ready, avoiding
z-fighting and unused square regions. The visible mesh follows native edits;
height-field normals are rebuilt on full refresh and the brush fast path for
consistent lighting and shadows. Atlas padding is clipped across all layers.

The v3 reconstruction uses neutral bright rock evidence and local contrast to
refine crests inside JSON mountain ranges. Explicit ridge guides take precedence;
noise is secondary. Lowland elevation and mountain relief have independent
controls. Bank width and a bounded shore grade form valleys/beaches instead of
vertical walls beside every water sample. Conservative supersampling within
water-tagged tiles retains thin rivers. Ocean-connected blue snow/mountain
shadows remain land unless a water tag or explicit guide overrides protection.

`aonw-reference-terrain/3` uses separate draft workspaces, preserving v2 sculpts.
Appearance-only edits do not alter the geometry recipe or rebuild heights.

## Vegetation

Forest neighbourhoods support a continuous canopy-evidence mask. Dark green
textured areas support woodland; bright clearings thin it. Forest boundaries are
not clipped into one patch per hex, and green fields alone do not imply forest.
An optional atlas-sized `forest_guide` (white woodland, black clearing) overrides
ambiguous inference. Assign it in the Inspector and rebuild. Invalid dimensions
are rejected before replacing the active terrain draft.

Tree3D creates six shared broadleaf/upland/tropical prototypes with textured
foliage and bark normals. A conservative alpha-cutout threshold retains small
mipmapped needle clusters and uses the same path in both renderers, instead of
renderer-dependent alpha hashing. Trunks have generated mesh LODs; foliage cards
are not destructively decimated. Spatially chunked MultiMeshes share the meshes.
Placement, scale, rotation and modest reference-derived tint are reproducible.
Density, spacing, height, slope limit, canopy threshold, reference influence,
conifer share and draw distance are adjustable. These are visual profiles, not a
botanical classifier. Defaults use smaller, more numerous trees than before.

Trees avoid water footprints and unsuitable tagged terrain. Snow can support
woodland when reference/context evidence agrees. Roots and slope eligibility
are re-evaluated against edited native heights after brush edits. Generated nodes
have no scene owner and never replace `ManualWorld`. Dynamic gameplay roads,
cities and untagged manual objects are not exclusion masks. Placement is capped
at 120,000 candidates and 20,000 trees, not a device-independent frame-rate promise.

## Water

Water is a separate clipped mesh using the same reconstructed footprint as the
terrain and forest exclusions. Metric shore distance controls shallow/deep
colour, shoreline treatment and ripple attenuation. Reference colours refine
the blue/turquoise palette. Depth, shore transition, ripple strength and colour
influence are adjustable. Rendered bed displacement never alters native heights.

Current maps use a zero-height water datum, with the preview surface 0.09 m above
it. This is opaque shallow/deep scattering with animated normals, not hydraulic
flow, volumetric refraction, flooding or inferred high-altitude lake levels.
Those require explicit water-body elevation/flow inputs. Full reference view
hides water and trees to avoid doubling the painted image with generated objects.

## Dependencies and scope

The installer verifies pinned Tree3D v1.1.0 archives and six 1k Poly Haven PBR
sets, records provenance, and refuses to overwrite unmanaged/modified assets.
Nothing downloads when Godot opens. Textures use imported resources; missing
assets produce warnings instead of pretending an empty forest is complete.

This remains an **authoring and rendered-preview pipeline**, not Terrain3D
control-map paint or a newly published gameplay terrain format. A painted atlas
does not establish exact geometry/species. Use forest/ridge/water guides for
ambiguous areas and inspect multiple zooms rather than assuming pixel-perfect
reconstruction or photorealism.

Tree3D is MIT: https://github.com/JekSun97/gdTree3D/releases/tag/v1.1.0 ; its notice
is retained at `addons/Tree3D/LICENSE.md`. Poly Haven scans are CC0:
https://polyhaven.com/license . IDs: `leafy_grass`, `forest_ground_04`,
`coast_sand_05`, `snow_02`, `rock_boulder_cracked`, `brown_mud_03`.
Preserve the installer's `assets.lock.json` for repeatable release installation.

## Validation

```sh
python3 clients/aonw_godot/tool/run_reference_contracts.py --godot /path/to/godot
python3 clients/aonw_godot/tool/run_reference_contracts.py --godot /path/to/godot --visual-assets
/path/to/godot --headless --audio-driver Dummy --path clients/aonw_godot --script res://tests/test_landscape_play.gd
/path/to/godot --audio-driver Dummy --path clients/aonw_godot --script res://tool/capture_reference_maps.gd
```

Use `xvfb-run -a` for render checks on display-less Linux. Pure contracts cover
water continuity, geometry sensitivity, biome weights, canopy evidence,
reproducibility and appearance/geometry isolation. The Play integration test
uses the real entry scene, native terrain, comparison visibility, brush updates
and invalid-guide protection. Full-map captures save perspective/top-down
landscapes, references, canopy masks and water masks to `reference-captures/`.
CI renders all four maps in Compatibility and Dravonia in Forward+, retaining
images/logs. These are visual inspection artifacts, not a photorealism or GPU
performance benchmark.
