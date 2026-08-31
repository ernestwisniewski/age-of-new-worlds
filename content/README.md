# Shared Logical Content

This directory contains versioned logical content consumed by Rust and client
presentation adapters. It is the source of truth for map topology, terrain,
resources, elevation, and objectives. Renderer meshes, textures, materials,
audio, and localization remain client-owned assets.

Map schema version 1 uses a complete odd-q, flat-top grid. Tiles are stored in
row-major order by the canonical serializer. The ordered `terrainTags` list is
the logical terrain source of truth. Its first value is the authored visual
identity, and its first non-river value owns the base economic yield. Movement
is normalized from the same profile. Authored JSON stores no duplicate
movement, display, or yield projections. Runtime domain code exposes those
named views from `TerrainProfile`, and client read models receive the derived
values without interpreting tag order themselves. Resource and objective order
is normalized by `aonw_content`, so content hashes remain deterministic.
`defaultZoom` is kept in the versioned document but excluded from logical
identity.

Maps under `content/maps/` are the only logical maps consumed by Rust, Flutter,
the server, and Godot. Final client-owned artwork is generated separately under
`assets/runtime/maps/`; private source artwork and unversioned map JSON are not
runtime inputs. All shared maps must use the schema in
`schemas/map-v1.schema.json`.

Every map directory also owns a required `terrain_authoring.json`. Its
`maxTerrainHeightMeters` maps logical height `5` to a map-specific metric
ceiling without changing gameplay rules or the logical map content hash.
Logical tile authoring is performed through Rust workbench commands. Each edit
replaces the canonical map/profile pair from validated Rust output, changes
`contentHash`, and refreshes the authoring profile identity; clients do not
construct these documents themselves.

Maps created by the Godot Workbench additionally retain
`map_generation.json` and `generated_decorations.json`. The former binds
the exact generation specification and seed to the hashes of the
generated documents. `blank` emits an empty presentation plan;
`continental` deterministically generates logical terrain, resources,
height, and concrete tree, rock, water, and detail placements. Godot batches
those placements under `GeneratedWorld`, independently of `ManualWorld` and
the manually sculpted Terrain3D final.

`content/scenarios/` contains strict starting placements bound to one map ID
and one immutable ruleset ID. Rust validates both content identities before it
bootstraps revision-zero `GameState`. Scenario v1 uses
`schemas/scenario-v1.schema.json`; `aonw2_starter` supplies the first Godot
local session.
