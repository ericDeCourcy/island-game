#!/usr/bin/env python3
"""
defleck.py — Remove 1x1 (and small) stray "flecks" from a pixel-art sprite that
was authored on a coarse logical grid and scaled up by an integer factor.

Idea
----
The real art lives on a GRID of NxN "logical pixels" (here 3x3 image pixels per
logical pixel). A real logical pixel is a SOLID, grid-aligned block: nearly all
of its N*N subpixels share one color. A "fleck" is an isolated stray pixel (1x1,
occasionally 2-4 px) that does NOT fill a grid cell.

So for each grid cell we take a majority vote over its N*N subpixels:
  - if >= THRESHOLD subpixels are opaque  -> it's a real block:
        fill the whole cell with the cell's dominant opaque color (this also
        cleans up any anti-aliasing on block edges).
  - else                                  -> it's flecks/noise:
        clear the whole cell to the background (transparent).

Because flecks are tiny they can never reach THRESHOLD within a single cell,
so they get wiped while solid blocks are preserved (and sharpened).

Works on animated GIFs (all frames), preserves timing, loop, and transparency.
"""

import argparse
from collections import Counter
import numpy as np
from PIL import Image, ImageSequence


def load_frames(path):
    """Return (list_of_RGBA_arrays, durations, loop)."""
    im = Image.open(path)
    frames, durations = [], []
    for fr in ImageSequence.Iterator(im):
        frames.append(np.array(fr.convert("RGBA")))
        durations.append(fr.info.get("duration", im.info.get("duration", 100)))
    loop = im.info.get("loop", 0)
    return frames, durations, loop


def detect_phase(alpha_stack, grid):
    """
    Find the (dy, dx) offset in 0..grid-1 that best aligns the grid to the art,
    by choosing the phase whose cells are the most 'pure' (all-opaque or
    all-transparent). Uses the union of opacity across all frames.
    """
    union = np.zeros(alpha_stack[0].shape, dtype=bool)
    for a in alpha_stack:
        union |= a
    H, W = union.shape
    best, best_score = (0, 0), -1
    for dy in range(grid):
        for dx in range(grid):
            score = 0
            for y in range(dy, H - grid + 1, grid):
                for x in range(dx, W - grid + 1, grid):
                    block = union[y:y + grid, x:x + grid]
                    s = block.sum()
                    if s == 0 or s == grid * grid:      # perfectly pure cell
                        score += 1
            if score > best_score:
                best_score, best = score, (dy, dx)
    return best


def defleck_frame(rgba, grid, phase, threshold, alpha_cutoff=128):
    """Apply per-cell majority vote to one RGBA frame."""
    H, W, _ = rgba.shape
    out = np.zeros_like(rgba)               # transparent background
    dy, dx = phase
    opaque = rgba[:, :, 3] >= alpha_cutoff

    # iterate over grid-aligned cells (including partial cells at the far edges)
    ys = list(range(dy, H, grid)); 
    if dy > 0: ys = [0] + ys                # catch the sliver before the phase start
    xs = list(range(dx, W, grid))
    if dx > 0: xs = [0] + xs

    for y in ys:
        for x in xs:
            # sliver cells (y==0 or x==0 under a nonzero phase) must stop at the
            # phase boundary, not run a full `grid` and overlap the next cell.
            ys_end = dy if (dy > 0 and y == 0) else min(y + grid, H)
            xs_end = dx if (dx > 0 and x == 0) else min(x + grid, W)
            cell_op = opaque[y:ys_end, x:xs_end]
            n_op = int(cell_op.sum())
            if n_op >= threshold:
                # dominant opaque color in this cell
                cell = rgba[y:ys_end, x:xs_end]
                px = [tuple(p) for p in cell[cell_op]]
                color = Counter(px).most_common(1)[0][0]
                out[y:ys_end, x:xs_end] = color
            # else: leave transparent (flecks removed)
    return out


def save_gif(frames, durations, loop, path):
    """Exact-palette GIF export (lossless for low-color pixel art).

    Index 0 is reserved for transparency; every distinct opaque color gets its
    own index. The palette is written explicitly with putpalette so it is NOT
    lost (the earlier bug: Image.fromarray(arr,'P') drops the palette)."""
    # gather all distinct opaque colors across every frame
    colors = {}
    for f in frames:
        op = f[:, :, 3] >= 128
        for px in map(tuple, f[op][:, :3]):
            if px not in colors:
                colors[px] = len(colors) + 1        # indices start at 1
    if len(colors) > 255:
        raise ValueError(f"too many colors ({len(colors)}) for exact palette")

    # flat RGB palette; index 0 = transparent (color value arbitrary)
    palette = [0, 0, 0]
    for c in colors:
        palette += list(c)
    palette += [0, 0, 0] * (256 - (len(palette) // 3))   # pad to 256 entries

    out_imgs = []
    for f in frames:
        H, W, _ = f.shape
        idx = np.zeros((H, W), dtype=np.uint8)           # 0 = transparent
        op = f[:, :, 3] >= 128
        ys, xs = np.where(op)
        for y, x in zip(ys, xs):
            idx[y, x] = colors[tuple(f[y, x, :3])]
        p = Image.fromarray(idx, "P")
        p.putpalette(palette)                            # <-- attach palette
        p.info["transparency"] = 0
        out_imgs.append(p)

    out_imgs[0].save(path, save_all=True, append_images=out_imgs[1:],
                     duration=durations, loop=loop, disposal=2, transparency=0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--grid", type=int, default=3, help="logical pixel size (px)")
    ap.add_argument("--threshold", type=int, default=None,
                    help="min opaque subpixels to keep a cell (default: majority)")
    args = ap.parse_args()

    grid = args.grid
    thr = args.threshold if args.threshold is not None else (grid * grid) // 2 + 1

    frames, durations, loop = load_frames(args.input)
    alpha_stack = [f[:, :, 3] >= 128 for f in frames]
    phase = detect_phase(alpha_stack, grid)

    cleaned = [defleck_frame(f, grid, phase, thr) for f in frames]

    # report
    before = sum(int((f[:, :, 3] >= 128).sum()) for f in frames)
    after = sum(int((f[:, :, 3] >= 128).sum()) for f in cleaned)
    print(f"grid={grid}  phase(dy,dx)={phase}  threshold={thr}/{grid*grid}")
    print(f"opaque px: {before} -> {after}  (removed {before-after})")

    save_gif(cleaned, durations, loop, args.output)
    print("wrote", args.output)


if __name__ == "__main__":
    main()
