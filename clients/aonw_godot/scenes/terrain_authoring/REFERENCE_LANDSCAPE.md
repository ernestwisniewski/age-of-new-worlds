# Reference landscape and Play preview

The `feature/maps-terrain` authoring workflow reconstructs terrain from canonical
JSON elevations/tags and the registered reference atlas, then presents real PBR
surface scans, Tree3D meshes and a separate water surface. No gameplay JSON,
manual objects, movement rules or existing canonical scenes are rewritten.

## Open and run

Close Godot and install the visual dependencies once from the repository root:

```sh
python3 clients/aonw_godot/tool/install_reference_assets.py
```

Restart Godot. Open a map in **AoNW Terrain3D**, apply any pending geometry edits,
then click **Play** in the dock or the normal **Play/F5** button. The editor saves
the current terrain draft and scene before launching; pending geometry blocks
Play with an explicit Apply/Discard message rather than rendering stale input.
The selected map/scene is remembered locally in `.godot/aonw_landscape_preview.cfg`.

F5 opens `landscape_play.tscn`: a rendered landscape with map selection, loading
status and Landscape / Reference / Compare / Grid controls. With no remembered
selection it opens Dravonia. F6 can still run any of the inherited scenes in
`reference_maps/` directly. The older gameplay prototype remains available at
`res://scenes/map_preview.tscn`; the F5 change is for this terrain-authoring branch.

Right drag orbits, middle/Shift-right drag pans, and the wheel/pinch zooms.
`1` shows the top-down reference, `2` the lit perspective landscape, `R` compares,
and `G` toggles hexes. The camera fits the actual map corners and viewport aspect
ratio instead of leaving the map far away inside a large empty native region.

## Colour and ground materials

Six scanned PBR layers cover grass, forest floor, sand, snow, rock and wet soil.
A smooth, metric-scale semantic prior is refined with registered reference
colour, brightness and local contrast. Low-frequency reference colour/value is
combined with mean-normalized scan detail; it is not the original image pasted
over 3D. The mean correction accounts for Compatibility's sRGB shading versus
Forward+'s linear space. Normal and roughness maps remain real material inputs.
Triplanar projection prevents stretched cliff textures. At most two dominant
layers are sampled per fragment. Blue water pixels do not tint cliffs cyan.

The material surface follows the native edited heights. Native Terrain3D still
owns data, editing constraints, collision and CPU picking, but its coincident
grey draw surface is hidden when the PBR surface is ready. This avoids depth
fighting and exposes no unused square regions. Smooth mesh normals are rebuilt
also on the native brush fast path, providing consistent lighting and shadows.
Black/transparent parts of the atlas boundary are clipped consistently in the
land, water and vegetation layers.

## Mountains, valleys and banks

The v3 reconstruction retains JSON location/elevation constraints but refines
crests using neutral bright rock evidence and local reference contrast. Explicit
ridge guides remain authoritative. Small-scale noise is secondary, not the
source of arbitrary mountains on plains. Lowland elevation and mountain relief
have independent controls. A bounded shore grade and adjustable bank width
produce river valleys and beaches rather than vertical walls beside every wet
sample. Narrow water features are conservatively supersampled within semantic
water tiles. Ocean-connected blue shadows on snow/mountain tiles remain land
unless an explicit water tag or water guide overrides that protection.

Geometry algorithm version `aonw-reference-terrain/3` creates separate draft
workspaces, preserving earlier sculpted v2 terrain. Appearance-only edits do not
alter the geometry recipe or trigger a height rebuild.

## Vegetation

JSON forest neighbourhoods support a continuous canopy-evidence mask. Dark green
textured areas support woodland; bright clearings thin it. Vegetation is not
clipped into one patch per hex and green fields alone are not treated as forest.
An optional atlas-sized `forest_guide` (white woodland, black clearing) overrides
ambiguous image inference. Assign it in the Inspector and rebuild; invalid guide
dimensions are rejected before replacing the active terrain draft.

Tree3D creates six shared prototypes, with broadleaf, upland and tropical forms,
textured foliage and bark normals. Alpha hashing preserves small, distant
canopies instead of cutting them away at a fixed alpha threshold. Their trunks
have generated LODs; foliage cards retain their coverage instead of being
destructively simplified. Meshes are shared through spatially chunked
MultiMeshes. Placement, scale, rotation
and modest reference-derived tint are reproducible. Density, spacing, height,
maximum slope, canopy threshold, reference influence, conifer share and draw
distance are adjustable. Defaults use smaller, more numerous trees than the
previous landscape preview. These are visual profiles, not a species classifier.

Trees avoid water footprints and unsuitable tagged terrain, but snow can support
woodland when the reference and semantic context support it. Roots and slope
eligibility are re-evaluated against edited native heights after brush edits.
Generated forests have no scene owner and never replace `ManualWorld`. Dynamic
gameplay roads/cities and untagged manually placed objects are not exclusion
masks. Placement is bounded to 120,000 candidates and 20,000 trees; this is not a
frame-rate guarantee for every device or slider combination.

## Water

Water is a separate clipped mesh, not blue ground paint. Its exact footprint
uses the same reconstructed water mask as the terrain and forest exclusions.
Metric distance to land controls shallow/deep colour, shoreline treatment and
wave-normal attenuation. Reference colours refine the blue/turquoise palette.
Depth, shore transition, ripples and reference-colour influence have controls.
The ground shader lowers the rendered bed beneath the surface without changing
the native gameplay/authoring water-height contract.

The current canonical maps have zero-height water; their preview surface is
0.09 m above that datum. This is opaque shallow/deep scattering with animated
normals, not hydraulic flow, volumetric refraction, flood simulation or inferred
high-altitude lake levels. These would need explicit per-water-body elevation
and flow inputs. A reference comparison hides water and trees so the original
image is not doubled by generated canopies or a second water layer.

## Dependencies and scope

The installer downloads pinned Tree3D v1.1.0 addon/demo archives and six 1k Poly
Haven PBR scans. It verifies integrity, records provenance, and refuses to
overwrite unmanaged/modified assets. Nothing downloads on opening Godot.
Textures are loaded through Godot's imported resource system. Missing visual
assets leave an explicit warning, not an apparently successful empty forest.

This remains an **authoring and rendered-preview pipeline**, not Terrain3D
control-map paint or a newly published gameplay terrain format. It does not
claim pixel-perfect semantic reconstruction from a single painted image.
Use forest/ridge/water guides for ambiguous features and review multiple zooms.

Tree3D is MIT: https://github.com/JekSun97/gdTree3D/releases/tag/v1.1.0 . Its notice
is retained in `addons/Tree3D/LICENSE.md`. Poly Haven scans are CC0:
https://polyhaven.com/license . Scan IDs are `leafy_grass`, `forest_ground_04`,
`coast_sand_05`, `snow_02`, `rock_boulder_cracked`, `brown_mud_03`. Preserve the
installer's `assets.lock.json` for repeatable release asset installation.

## Validation

```sh
python3 clients/aonw_godot/tool/run_reference_contracts.py --godot /path/to/godot
python3 clients/aonw_godot/tool/run_reference_contracts.py --godot /path/to/godot --visual-assets
/path/to/godot --headless --audio-driver Dummy --path clients/aonw_godot --script res://tests/test_landscape_play.gd
/path/to/godot --audio-driver Dummy --path clients/aonw_godot --script res://tool/capture_reference_maps.gd
```

On display-less Linux use `xvfb-run -a` for renderer checks. Pure contracts cover
water continuity, geometry parameter sensitivity, normalized biome weights,
canopy evidence, reproducibility and appearance/geometry isolation. The F5 test
uses the actual launcher, native terrain, comparison visibility and brush
re-seating. Full-map captures save perspective landscape, top-down landscape,
reference, canopy and water-mask images under `reference-captures/`. These are
inspection artifacts, not numerical proof of photorealism or a GPU benchmark.
