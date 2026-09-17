# Natural woodland and finer water profiles — all reference maps

The shared reference landscape template now defaults to **Natural groves**.
Forest placement and tree colour no longer need to follow painted woodland.
JSON biome neighbourhoods still determine suitable habitat, while seeded
multi-octave noise creates connected groves, dense interiors, soft edges and
clearings across hex boundaries. The atlas still supplies ground colours,
landform/water evidence and map-padding coverage. `forest_guide` remains an
explicit artist override. **Reference** mode retains the earlier placement path.

## City-scale vegetation

The default represented hex diameter is now 240 model metres, tree height 8 m
and spacing 6 m, all using the same model-to-map conversion as CityModelAnchor.
For a 10-unit hex radius this gives about 0.67-unit trees and desired 0.5-unit
spacing. These are art conventions, not the tile's geographical area. The city
core reservation, full-crown clearance and exact forest restoration are retained.

Only blocks containing woodland receive procedural candidate-grid work. The
budget is 240,000 visited grid cells and 40,000 trees by default (slider range
1,000–80,000). A global, deterministic selection prevents the first rows of a
map from consuming the entire tree budget. City filtering remains after this
selection, so reserving one city does not reseed forests elsewhere. Water,
invalid tiles and steep terrain still reject placements. The status reports
when a candidate or tree budget reduces the requested density; it is not a
promise that every large map reaches the requested spacing or frame rate.

Controls: **Forest layout**, **Forest patch size**, **Woodland patch coverage**,
**Woodland edge softness**, **Density inside forest patches**, and
**Maximum generated trees**. Tree height/spacing are in the City hex section.
Reference-only sliders are disabled in natural mode. Camera/light changes do
not regenerate distribution. Mask updates finish before a forest rebuild can
report itself ready.

## River and basin detail

The v4 geometry recipe supersamples water evidence up to 3x3 per raster sample
inside water-tagged regions. Weak teal/blue shoreline pixels can join strongly
seeded water, but cannot create unseeded lakes. Snow/mountain protection and
explicit guides still take precedence. **Shoreline samples per axis** and
**Lowland river-bank grade** affect actual generation, not only a shader hash.
No-reference maps still use canonical semantic water tags.

A shared signed-distance profile drives both the visible bed and the separate
water surface. Distances are in map metres, including the half-cell shoreline
correction. GPU sampling is aligned to CPU raster nodes rather than shifted by
half a texel. The filtered GPU profile uses RGBA16F, not RGBA32F: half the
texture memory and no reliance on optional Metal float32 filtering support.
Far-field distances saturate at 60,000 m to avoid half-float overflow; native
water masks and near-shore distances are retained. Single-cell channels and dry islands are retained; the profile
does not run an island-removing blur. A tiny 0.02-cell rendering tolerance joins
diagonal river contacts without changing the native water mask. Narrow water
remains shallow; wider basins deepen smoothly. **Water-bed grade** controls this
profile. Ripples follow local along-bank direction and weaken in narrow/shallow
water. This is an artistic ripple direction, not upstream/downstream flow.

Native water heights still use the canonical zero datum. This is not hydraulic
simulation, volumetric refraction or inferred high-altitude lake elevations.
Detail remains bounded by the native raster and source image; supersampling
does not recover details absent from both. Water, plants and city safety use
the same reconstructed water footprint.

## Existing maps and saved settings

All maps inheriting `reference_terrain.tscn` use the same implementation,
including `aonw2_starter` and newly discovered bundles. Opening an old scene
migrates former default tree density/scale values once; deliberately different
values are preserved. No files are bulk-overwritten. Save the scene to persist
the migration revision. New grove settings have defaults even in previously
saved parameter dictionaries.

The changed shoreline algorithm uses `aonw-reference-terrain/4` and a separate
recipe workspace. Old v3 sculpt drafts remain on disk; they are **not silently
transferred into the new geometry**. Opening/rebuilding creates the new base.
Appearance-only adjustments stay in the current workspace. Play/F5 and the
editor share the settings. No new asset installation is needed for an already
working Tree3D/PBR setup.

## Validation

`test_forest_water_generation.gd` covers procedural repeatability, changed seeds,
patch control effects, independence from painted forest colour, active-block
budgets, no duplicate grid cells, default migration, water exclusion, metric
shore distances and island retention. Geometry parameter sensitivity includes
supersampling a thinner-than-raster stream and changes to the actual carved
heights. City native tests still check reservation/removal/restoration.

`test_natural_landscape_maps.gd` waits for the fully generated scene for every
map bundle and checks defaults, masks, budgets and native zero-height water.
The capture tool discovers all bundles rather than a hardcoded four-map list.
Render captures are visual evidence, not a photorealism or performance score.

Metal format support: https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
