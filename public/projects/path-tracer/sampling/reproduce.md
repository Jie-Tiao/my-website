# Reproducing the GGX sampling study

The experiment is implemented in the local CPU-path-tracer_ source repository:
`sampling_benchmark.cc`, `scripts/benchmark_sampling.py`, and `tests/sampling_tests.cc`.
The underlying project is https://github.com/Jie-Tiao/CPU-path-tracer_ .
Use a revision containing those files; this portfolio edit does not publish source changes.

```sh
cmake -S . -B build-model -DCMAKE_BUILD_TYPE=Release
cmake --build build-model --target sampling_benchmark sampling_tests
ctest --test-dir build-model --output-on-failure
# Python 3.9+ in an isolated environment
python3 -m venv .venv-sampling
.venv-sampling/bin/pip install numpy pillow matplotlib
.venv-sampling/bin/python scripts/benchmark_sampling.py
```

Default settings:

- 144 x 96 image, maximum depth 12, one thread.
- Three gold metallic spheres with roughness 0.2, 0.45 and 0.8; diffuse floor;
  a rectangular area light and constant environment.
- Identical BRDF for all methods. Only the specular proposal changes.
- Original integrator's 50/50 light/material mixture stays enabled.
- IID jittered camera rays in complete image passes; exact requested SPP.
- Equal-SPP: 16, 64, 256 and 1024 SPP; seeds 101, 211, 307, 401, 503.
- Equal-time: 2-second target per run, same seeds; complete the last pass and
  record the actual elapsed time and SPP. Sequential runs, rotated method order.
- Two independent VNDF references: 32768 SPP each, seeds 900001 and 900007,
  averaged for a total of 65536 SPP.
- Linear RGB MSE is averaged over every pixel and all three channels, without
  display correction or clipping. The reference is itself a Monte Carlo estimate.
- Reference-pair MSE / 4 estimates the remaining MSE of the averaged reference;
  it is not a strict upper bound.
- Timing includes initialization, allocation, sampling, tracing and accumulation,
  excluding scene construction and file I/O.
- Tables show sample standard deviation; plotted error bars show standard error
  of the five MSE observations. Do not read these as guarantees for other scenes.
- Efficiency is the mean of per-run 1/(actual seconds * MSE), rather than the
  reciprocal of the product of the two means.

Display PNGs use the same square-root transformation with clipping for display
only, without denoising. The representative image always uses seed 101.

Files in the portfolio:

- `runs.csv`: all 75 individual test measurements.
- `results.json`: complete settings, binary SHA256, summaries and reference noise.
- `convergence.svg`: same-SPP MSE curves.
- `equal-time.svg`: same-time MSE comparison.
- `comparison-spp.png` and `comparison-time.png`: four-panel render comparisons.
- `reference-linear.npy`: averaged reference as float64 RGB, shape (96, 144, 3).

Full raw linear images and render logs are preserved locally in
`build-model/sampling-study/`. This build directory is ignored by Git.

Sampler formulas/reference:
https://pbr-book.org/4ed/Reflection_Models/Roughness_Using_Microfacet_Theory
