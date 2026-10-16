# SAH vs ordinary BVH — measured comparison, 2026-10-15

Ordinary BVH is the current longest-bounding-box-axis median builder.
SAH is the current 12-bin, three-axis builder. Leaves differ: median 1–2 primitives, SAH up to 4.
This compares the complete existing modes, rather than isolating the split heuristic alone.

## Conditions

Release C++ build, macOS arm64, 64 spp, one thread, fixed seed 1.
One warmup per mode, followed by five measured runs per mode with alternating order.
All renders ran sequentially. Per-scene SHA256 checks confirmed every measured and warmup output was byte-identical.
Render wall time includes PPM output and excludes loading and BVH construction.
Mesh build time is recorded separately; it excludes OBJ and texture loading.

## Median results

| Scene | Triangles | Resolution | Median BVH render | SAH render | Speedup | Time reduction |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| spot | 5,856 | 320×320 | 5.144 s | 4.466 s | 1.152× | 13.2% |
| dragon | 871,306 | 320×256 | 8.221 s | 6.431 s | 1.278× | 21.8% |

| Scene | Median BVH mesh build | SAH mesh build |
| --- | ---: | ---: |
| spot | 3.42 ms | 3.78 ms |
| dragon | 1467.17 ms | 1376.10 ms |

## Interpretation

SAH improved rendering time on both tested meshes; the observed reduction was larger on Dragon.
These scenes also differ in camera, geometry and shading, so triangle count alone does not explain the difference.
System-load variation occurred, most visibly in the final Dragon round: median BVH build 13.8704 s, median render 9.69577 s, SAH render 9.11335 s. No runs were excluded.
Use these as local scene-specific measurements, not universal speedup claims.

## Reproduce

```sh
cmake --build build-model --target CPUPathTracer
python3 scripts/benchmark_dragon.py --scene dragon --width 320 --samples 64 --runs 5 --output build-model/bvh-comparison-dragon-new
python3 scripts/benchmark_dragon.py --scene model --width 320 --samples 64 --runs 5 --output build-model/bvh-comparison-spot-new
```

Full logs and PPMs remain under `build-model/bvh-comparison-{scene}-20261015/`.
This folder retains measured CSVs, configuration manifests including the binary hash, and summary JSON.
