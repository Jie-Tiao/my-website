# Multithreaded rendering — 2026-10-15

Cornell Box, 240×240, 64 spp, depth 50, SAH BVH, Release, macOS arm64.
Per-pixel deterministic streams, seed 1; all 25 measured images plus 5 warmups are byte-identical.
Each configuration: one warmup then five measured runs, sequential with rotating order.
Wall time includes initialization, allocation, worker creation/join, tracing and PPM output; excludes scene/BVH build.

| RNG | Scheduler | Threads | Runs | Median (s) | Speedup vs matching 1-thread baseline |
| --- | --- | ---: | ---: | ---: | ---: |
| pixel | row | 1 | 5 | 4.67028 | 1.000× |
| pixel | row | 2 | 5 | 2.64850 | 1.763× |
| pixel | row | 4 | 5 | 1.60036 | 2.918× |
| pixel | row | 8 | 5 | 1.76727 | 2.643× |
| pixel | tile | 4 | 5 | 1.59568 | 2.927× |
| legacy | row | 1 | 3 | 4.73424 | 1.000× |
| legacy | row | 4 | 3 | 1.67301 | 2.830× |

Four row workers were the fastest tested row configuration: 4.67028 → 1.60036 seconds (2.918×).
Eight row workers were slower (1.76727 seconds); the measurements do not establish a hardware-level cause.
At four threads, tiles took 1.59568 seconds vs rows 1.60036 seconds. This 0.3% difference is smaller than run-to-run variation; there is no clear tile benefit.

The deterministic mode is newly added and opt-in (`--deterministic`). It uses pixel-seeded xorshift64* state in thread-local storage; unchanged sampling sequences enable exact output checks across schedules.
Default renderer behavior still uses the original std::rand() mode. This control was measured separately at 1/4 threads (three runs each), giving 2.830× speedup. Its multi-thread images are not guaranteed identical.
Do not compare absolute times with historical runs at unspecified settings. Do not attribute any difference between RNG modes solely to contention: the generator and sampling paths also changed.

## Reproduce

```sh
cmake -S . -B build-model -DCMAKE_BUILD_TYPE=Release
cmake --build build-model --target CPUPathTracer
python3 scripts/benchmark_threads.py --output build-model/thread-study-new
ctest --test-dir build-model --output-on-failure
```

Full PPM files and logs remain in `build-model/thread-study-20261015/`.
The run CSV includes wall time and the narrower worker-only timer; portfolio results use wall time consistently.
No samples or runs were discarded. These measurements apply to this scene on the tested machine.
