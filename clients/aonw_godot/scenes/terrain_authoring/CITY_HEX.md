# A city and its surroundings inside one hex

The new default **City hex** vegetation scale treats one corner-to-corner hex
as 240 model metres. This is a visual design convention, not a claim about the
geographic area represented by a gameplay tile. Native heights, map radius,
water and picking are unchanged by city scaling. The separate v4 shoreline
upgrade is documented in [FORESTS_AND_WATER.md](FORESTS_AND_WATER.md).

`map_units_per_model_metre = 2 * hex_radius_meters / city_hex_diameter`

At the current 10-unit radius, the conversion is 1/12. An 8 m tree is about
0.67 map units before variation, instead of the previous 1.5-unit tree. A future
10 m house is about 0.83 map units; a 2 m rock is about 0.17. The conversion is uniform and shared with
the city-model anchor, so changing the hex size retains these proportions.
Existing tree-height/spacing settings are retained, not overwritten: choose
**Legacy metres** to use them again. The desired tree spacing is scaled too;
the existing 240,000-candidate/configurable tree budgets can make it coarser on large
maps. The patch does not install additional rock or building assets.

## Prepare one city plot

In the AoNW terrain panel, open a reference map. The new **City hex · scale and
footprint** section contains scale, represented diameter, tree height/spacing,
reservation and footprint controls. Select the plot with the existing city
marker Column/Row controls and switch **Reserve marked city hex** to **On**.
Turn on the existing city marker checkbox to display the draped guides.

The default layout stays inside the selected hex:

- building core: 0.42 of the hex radius, cleared of whole crowns;
- outskirts: vegetation returns gradually up to radius 0.76;
- outer band: natural vegetation follows the selected forest mode and terrain.

The reservation is **off by default**. Enabling the guide alone does not cut
trees. Other tiles do not become empty circular plots. Filtering happens after
deterministic candidate generation and its global budget, using actual shared
Tree3D mesh extents including offsets/scale. Crown bounds use a conservative
horizontal circle valid under random rotation. Disabling the reservation
restores the original instances rather than redistributing the entire forest.

The complete core is checked against the reconstructed water mask and edited
native terrain, not only its centre. Water/ice tiles, water crossing the core,
missing samples and slopes above the authoring profile's `maxCitySlope` grade
(default 0.35) produce a warning and do not clear vegetation. No automatic
flattening, relocation or river filling occurs. Brush edits revalidate the
reservation. This is a visual suitability check, not a new gameplay settlement
rule. Gentle slopes can still require terraces or terrain-conforming buildings.

## Future city mockup

An optional `city_preview_scene: PackedScene` is available on the reference
landscape root in the Inspector. Use a Node3D root, Y-up, modelled in metres,
with the city centre at XZ origin and its ground datum at Y=0. A generated
`CityHexPreview/CityModelAnchor` seats it at the native centre height with the
same uniform scale as the trees. Keep the building footprint inside the core;
the system does not automatically trim or flatten an arbitrary imported model.
Core/outskirts radii in model metres are available as anchor metadata.

`city_site_layout()` exposes a copied presentation layout: coordinate, centre,
core/outskirts/hex radii, scale and sampled height range. The pure
`city_hex_layout.gd` provides `model_scale()` and `vegetation_weight()` for
future rock, shrub and building integrations; current filtering covers the
reference Tree3D forest only. ManualWorld and other manually authored objects
are not deleted or moved.

Guides, anchor and instantiated mockup are derived and ownerless. Save the
scene to preserve the parameter values, marker coordinate and PackedScene
reference, not generated mesh children. The existing Play/F5 and F6 paths use
the same preview. Full-opacity reference mode hides the generated city/forest.
The original core marker is replaced by draped rings only for a valid active
reservation. The feature does not create city entities or enable gameplay
publication of reference drafts.

## Tests

`test_city_hex_layout.gd` covers proportions at multiple hex sizes, legacy
values, core/outer containment, full-crown clearance, water away from centre,
steep/missing terrain, model anchors and geometry-recipe isolation. It is part
of `tool/run_reference_contracts.py`.

`test_city_hex_native.gd` exercises the actual Dravonia reference scene with
native Terrain3D and Tree3D: instance removal/restoration, invalid coordinates,
save ownership, reference visibility, and no height/workspace changes. The
rendered-map workflow runs it and retains `reference-captures/city-hex.png`.
These are implementation checks, not proof of final city artwork or frame rate.
