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

All Flame frame windows use engine timestamps after 12 warm-up frames and
collect 60 consecutive frames. This avoids VM timeline allocation in the RSS
measurement. The device test verifies loaded sprite frames before sampling.

The Flame device test also saturates the four combat slots with eight damage
labels and 136 city-hit particles on the 40×30 scene. It measures 60 consecutive
engine frame timestamps after 12 warm-up frames. Effects run at 0.1 playback
speed to keep all slots occupied during live device pumps; the measured window
asserts the same occupancy at both ends. The combat record uses the same frame
and 192 MiB total RSS limits as the static scene. It uses synthetic accepted
combat evidence and excludes fog and HUD; it does not replace the full-scene
parity gate.

A third window renders three clouds with 33 puffs over the discovered clip.
Each cloud caches its soft shape in one image; movement only changes position,
rotation and opacity. The record includes the camera focus and cloud age so the
measured group stays in the starting viewport region. It includes all 1200
hexes in the cloud clip but excludes fog shading and HUD. Coverage of newly
visible atlas groups during wider camera travel remains a separate parity QA
requirement. Both transient workloads verify that Flame stops updating after
effects are disabled.
