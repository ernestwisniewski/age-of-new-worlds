# Performance benchmarks

Engine benchmarks separate portable structural evidence from host-local timing.
Every measured operation publishes a deterministic result signature, allocation
counts, allocated bytes, payload bytes, and—where applicable—domain work counters.
Wall-clock samples are diagnostic unless a policy pins the complete environment.

## Portable structural gate

Every regular engine quality run ratchets the exact workload census and result
signatures together with iteration, allocation, allocated-byte, payload, and
domain work-counter ceilings:

```sh
make engine-performance-check
```

The reviewed baseline is `engine/quality/performance_baseline.json`. Generate a
candidate with `make engine-performance-snapshot`; never install it without
reviewing why each changed signature or ceiling differs.

## Complete runtime gate

The hard latency gate measures accepted operations through the local
runtime on the pinned macOS arm64 reference device. The workloads cover:

- engine execution, aggregate validation, digest, recipient projection, and diff;
- the same movement operation through JSON decode and response encoding;
- the three independent large-map selection queries used by a controlled worker;
- a representative combat operation through JSON;
- late-turn timeout finalization with 512 units.

The reviewed policy is
`engine/quality/runtime_performance_policy.json`. It pins the hardware, OS,
Rust toolchain, benchmark profile, warm-up, sample count, output signatures,
allocation ceilings, allocated-byte ceilings, payload ceilings, and absolute p95
latency. A different environment fails closed instead of pretending its timings
are comparable.

```sh
make engine-runtime-performance-check
```

To collect a report without accepting it as a gate result:

```sh
make engine-runtime-performance-report
```

Reports default to `/tmp/aonw-engine-runtime-performance.json` and are not
committed. Rebaseline only after reviewing the benchmark workload and the cause
of every signature, work, allocation, payload, or timing change.

The selection measurements deliberately keep `reachable`, logistics, and worker
options separate. The client publishes reachable feedback first and loads the
independent panels afterward. A combined `SelectionContext` request would add
cross-feature coupling without removing the measured engine work, so it is not
introduced. Reconsider batching only if a pinned client/device trace shows that
the serialized native crossings—not one of the queries—exceed the interaction
budget.

## Exploratory engine benchmarks

The complete deterministic workload suite remains available for profiling:

```sh
make engine-benchmark
```

It covers map lookup, movement, logistics, combat, cities, workers, turn
finalization, persistence/replay, and AI planners. Shared-runner timings from this
command remain diagnostic; the stable structural baseline is
`engine/quality/performance_baseline.json`.

## Flutter frame budget

Flutter frame timing is a separate device gate because it includes build/raster,
Flame patch application, assets, and platform scheduling:

```sh
make flutter-client-performance-check
```

The committed records under `clients/aonw_flutter/performance/` state their
device, workload, build mode, warm-up, percentiles, and resource budgets. Engine
runtime latency must not be inferred from a frame golden, and renderer timing
must not be inferred from a headless Rust benchmark.

All Flame frame windows use engine timestamps after 12 warm-up pumps and
60 measured pumps (at least 60 engine frames; high-refresh devices can emit more). This avoids VM timeline allocation in the RSS
measurement. The device test verifies loaded sprite frames before sampling.

The Flame device test also saturates the four combat slots with eight damage
labels and 136 city-hit particles on the 40×30 scene. It collects engine frame timestamps over 60 measured pumps after 12 warm-up
pumps. Effects run at 0.1 playback
speed to keep all slots occupied during live device pumps; the measured window
asserts the same occupancy at both ends. The combat record uses the same frame
and 192 MiB total RSS limits as the static scene. It uses synthetic accepted
combat evidence and excludes fog and HUD; the full-scene gate below measures these effects with fog and HUD.

A third window renders three clouds with 33 puffs over the discovered clip.
Each cloud caches its soft shape in one image; movement only changes position,
rotation and opacity. The record includes the camera focus and cloud age so the
measured group stays in the starting viewport region. It includes all 1200
hexes in the cloud clip but excludes fog shading and HUD. Coverage of newly
visible atlas groups during wider camera travel remains a separate parity QA
requirement. Both transient workloads verify that Flame stops updating after
effects are disabled.

## Full map and HUD device gate

```sh
make flutter-client-full-hud-performance-check
```

This profile-mode macOS integration test mounts the production `MapScreen`,
including its HUD, input routing and overlays. The fixed presentation fixture
contains 40×30 tiles, 120 units, 40 cities, 120 improvements, 120 roads and
visible/discovered/hidden fog regions. All unit frames and city/improvement frames inside the camera prefetch margin must finish loading
before sampling. Separate windows cover the complete static map, 72 cursor
changes and four simultaneous combats with eight damage labels and 136 particles.
Hover must preserve scene writes, tile cache writes and unit component identity;
unmount must release every shared atlas.

The [reviewed record](../clients/aonw_flutter/performance/full_hud_baseline.json)
reports p99 build/raster times of 0.760/3.161 ms for the map, 0.789/3.319 ms for
hover and 0.746/4.047 ms for combat, with no missed budgets. The scene RSS delta
was 140,902,400 bytes, within the unchanged 192 MiB limit. The memory baseline
is a localized app shell before constructing the scene, matching entry from
the running menu. Idle unit animations are disabled for the idle assertion; the combat
window explicitly runs its effects.

Profile mode avoids charging JIT compilation to the scene's memory delta.
Exploratory debug runs crossed the RSS limit, including a cold-shell run at
215,973,888 bytes and a warmed hover run at 207,552,512 bytes; those are not
reported as passing profile evidence. Build modes and memory baselines are
recorded separately from the existing renderer-only debug records.

This is a rendering workload using fixed recipient views, not a replacement
for native-engine gameplay or multiplayer correctness tests. The release gate
includes this target. Broader camera travel and all-screen/device visual parity
remain separate QA work.

The renderer-only profile run after camera-based sprite ownership passed the
static, idle, worker, combat-animation, route and combat windows. The era
transition window failed its unchanged raster limit twice (p99 57.888 ms and
46.745 ms, including one run with the Rust gate paused). This remains an open
release-gate failure; the passing full-HUD record does not supersede it.


A subsequent complete renderer attempt uses `benchmarkLive` so native frames
continue when the test window loses focus; it retains engine-timestamp timing
windows and every existing limit. City-production reporting now reads the actual
world child count instead of a stale literal. With the owned Rust gate paused,
static rendering, route, combat, era tint, map events, floating text, production
and clouds passed. Production p99 build/raster was 0.743/2.990 ms, with zero
missed frames and a resident-memory delta of 159,416,320 bytes.

Camera focus remains failing: p99 build/raster was 1.098/14.195 ms, but one raster
frame took 63.531 ms and resident-memory delta reached 264,568,832 bytes, above
the unchanged 201,326,592-byte ceiling. The test stops at that failure; the later
movement-camera scenarios were not measured in this attempt. An earlier live
attempt failed during production, so the latest passing production window does
not establish that failure's cause. No passing baseline is substituted for these
incomplete runs, and the full renderer release gate remains open.


After preserving warm atlas ownership across an incoming request, another profile
run reached camera focus with p99 build/raster of 1.248/13.682 ms and zero missed
frames. Resident-memory delta still failed at 279,150,592 bytes. The camera probe
now records atlas bytes on both sides of the timing window: the initial city and
commander atlases total 25,486,848 bytes; four improvement atlases add 26,068,224
bytes by the end. These are decoded sprite bytes, not total process or GPU
memory. The ownership regression is fixed, but the release-memory gate remains
open and later movement-camera scenarios still were not reached.

Lossless static sprite partitioning reduced the camera-focus RSS delta to
212,156,416 bytes (previously 279,150,592). Live atlas memory fell from 51,555,072
to 17,267,596 bytes. Camera build/raster p99 were 1.443/14.058 ms, with zero missed
frames. The unchanged 201,326,592-byte memory limit still fails by 10,829,824 bytes;
later movement-camera scenarios were not reached. Source pixels and geometry for
all 100 moved frames pass the independent native-decoder regression. This is a
measured improvement, not a passing renderer release gate.

Loading native asset buffers and eagerly disposing the image descriptor and codec
further reduced camera-focus RSS delta to 205,176,832 bytes. Build/raster p99 were
0.967/12.163 ms with zero missed frames. The memory gate remains open, exceeding
its unchanged limit by 3,850,240 bytes. Invalid image metadata and an atlas closed
while its buffer is loading both release the buffer; decoded images remain owned
by their atlas scopes.

Partitioning city profiles further reduces a visible city's decoded page to
668,736 bytes. The full MapScreen/HUD profile passes: map p99 build/raster
0.698/2.816 ms, hover 0.728/2.840 ms, RSS delta 102,514,688 bytes; combat RSS delta
119,226,368 bytes. The committed full-HUD baseline records this complete run.
The separate renderer camera-focus attempt still fails memory at 210,698,240
bytes despite passing frame times (1.170/14.238 ms, zero missed frames). Whole
process memory did not fall proportionally to atlas bytes, so further allocation
work and movement-camera evidence remain required.
