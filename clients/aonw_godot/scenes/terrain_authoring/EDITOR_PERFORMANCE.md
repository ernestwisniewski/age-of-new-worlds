# Responsive landscape editing

The shared map authoring scene now starts in **responsive editor preview**.
This changes only what the editor draws, not map data or the full forest.
Play/F5, F6 and runtime capture tools always use the complete forest with the
original materials, wind, water animation and shadows.

## Controls

In the AoNW Terrain3D dock, **Full-quality editor preview** switches between
responsive editing and the complete scene. The same setting is exposed as
`editor_fast_preview` on the scene root. `editor_tree_budget` in the Inspector
is a draw budget (default 6,000), separate from the generator's tree budget.
These settings are ignored outside the editor and never enter geometry recipes.
The status displays the full generated count and the responsive visible count.

Responsive mode displays a deterministic, spatially distributed subset of the
existing forest, disables its tree shadows and freezes wind/water animation.
It does not delete trees, change their size or move them. Full quality restores
the same instance buffers immediately; no regeneration is needed. This preview
trade-off preserves the previous dense small-tree output in Play. Other objects,
city reservations and manually authored objects are not thinned or moved.

## Avoiding repeated work

The dock thumbnail is now a dirty snapshot, capped at 10 refresh requests per
second. It updates on camera, landscape or viewport changes, not every frame.
Hidden tabs and scrolled-out thumbnails stop rendering; rebinding the same
surface during UI synchronization does not request a new frame. The thumbnail
renders at half its display dimensions. Use Play for continuous full animation.

Forest instance transforms and custom data are uploaded in one packed buffer
per batch instead of two calls for every tree part. Smaller 64-unit spatial
chunks improve off-screen culling. Each chunk has a stable priority order so
responsive draw limits do not remove only one side of a grove; trunks and
canopies always share the same visible prefix. Allocation respects one global
draw budget rather than a separate limit for every chunk.

The renderer caches native height/slope samples. Local brush edits invalidate
only roots whose sampling footprint intersects the changed region. Candidate
changes or a new terrain base clear the cache. City or slope filtering reuses
valid samples; camera/light/draw-distance edits do not regenerate candidates.
Editor brush events coalesce for 0.65 seconds before forest re-seating.

For identity-aligned reference terrain, a brush update visits only the changed
raster rectangle instead of scanning the entire terrain. Normal calculation
updates that rectangle plus a one-sample halo. Transformed overlays retain the
full safe path. The mesh buffer still requires upload: this is not a claim of
zero-cost brushing or a fully incremental terrain mesh renderer. Opening a map
also avoids rebuilding its already-created surface/grid merely to set materials.

## Validation and limitations

`test_editor_landscape_performance.gd` checks paired draw budgets, restoration
without buffer edits, packed transforms/custom data, unchanged-height cache
hits, local invalidation, incremental/full normal parity and idle/hidden viewport
refreshes. Run with a real renderer to verify GPU buffer round trips; the dummy
headless renderer does not store uploaded GPU buffers.

`test_editor_landscape_native.gd` runs with and without `--editor` on the actual
Dravonia scene: editor/runtime separation, immediate quality switching, camera,
light, draw-distance and city-marker changes without candidate regeneration.
The rendered-map workflow runs both tests as well as the existing all-map tests.

This reduces steady-state editor drawing and repeat edits. Initial terrain/mask
and forest generation remain synchronous; large maps can still pause while they
are first built. It does not promise an FPS figure on any particular GPU. For
frame timing on your machine, compare the same map/camera with full-quality
editor preview off/on after generation has completed, and measure Play separately.

Godot references:
https://docs.godotengine.org/en/stable/classes/class_subviewport.html
https://docs.godotengine.org/en/stable/classes/class_multimesh.html
