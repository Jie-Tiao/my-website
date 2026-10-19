"""Export the built inline diagrams as self-contained SVGs for full-size viewing.
Run after astro build, then rebuild to include the exported assets in dist.
"""
from pathlib import Path
import re, base64
root = Path(__file__).resolve().parents[1]
html = (root / 'dist/projects/shadow-runner/index.html').read_text()
for svg in re.findall(r'<svg\b.*?</svg>', html, flags=re.S):
    match = re.search(r'<image href="/projects/shadow-runner/((?:prototype|release)-(?:walls|switch))\.webp"', svg)
    if not match:
        continue
    name = match.group(1)
    def embed(m):
        image = root / 'public' / m.group(1).lstrip('/')
        return 'href="data:image/webp;base64,' + base64.b64encode(image.read_bytes()).decode() + '"'
    svg = re.sub(r' data-astro-cid-[a-z0-9]+', '', svg)
    svg = re.sub(r'href="(/projects/shadow-runner/[^\"]+\.webp)"', embed, svg)
    svg = svg.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ', 1)
    svg = svg.replace('>', '><style>text{font:700 24px monospace;fill:#192822}</style>', 1)
    (root / f'public/projects/shadow-runner/{name}-annotated.svg').write_text(svg)
    print(name)
