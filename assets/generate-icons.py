#!/usr/bin/env python3
"""One-off build script: renders a mascot silhouette as a battery-gauge icon
at 6 discrete remaining-percentage levels (100/80/60/40/20/0). Run manually
whenever the icon design needs to be regenerated; the SwiftBar plugin script
only reads the pre-rendered PNGs already committed under assets/, no runtime
image processing.

NOTE: this script is included for provenance/documentation, but is not
runnable as-is — REF_IMAGE below must point at a source silhouette PNG
(black shape on transparent/black background) that isn't part of this repo.
Point it at your own reference image, or just edit the pre-rendered
icon-*.png files directly if you want a different look.
"""

import numpy as np
from PIL import Image

SCRIPT_DIR = __import__("pathlib").Path(__file__).parent
REF_IMAGE = "path/to/your-icon-reference.png"  # not included in this repo, see note above

OUT_HEIGHT = 18  # px, retina-friendly for a ~20pt menu bar icon
FILL_ORANGE = (206, 142, 107, 255)  # Claude clay/orange, sampled from the mascot
WARNING_RED = (214, 68, 58, 255)
EMPTY_GRAY = (150, 150, 150, 90)
OUTLINE = (20, 20, 20, 200)

LEVELS = [100, 80, 60, 40, 20, 0]


def load_mask():
    im = Image.open(REF_IMAGE).convert("RGBA")
    arr = np.array(im)
    rgb = arr[:, :, :3].astype(int)
    fg = rgb.sum(axis=2) > 30  # non-black pixels = mascot silhouette
    ys, xs = np.where(fg)
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    return fg[y0 : y1 + 1, x0 : x1 + 1]


def dilate(mask):
    padded = np.pad(mask, 1)
    out = padded.copy()
    out[1:-1, :] |= padded[:-2, :] | padded[2:, :]
    out[:, 1:-1] |= padded[:, :-2] | padded[:, 2:]
    return out[1:-1, 1:-1] | mask


def render(mask, level, out_path):
    h, w = mask.shape
    fill_rows = round(h * level / 100)
    fill_color = WARNING_RED if level <= 20 else FILL_ORANGE
    canvas = np.zeros((h, w, 4), dtype=np.uint8)
    outline_mask = dilate(mask) & ~mask
    canvas[outline_mask] = OUTLINE
    for y in range(h):
        from_bottom = h - 1 - y
        row_mask = mask[y]
        if from_bottom < fill_rows:
            canvas[y][row_mask] = fill_color
        else:
            canvas[y][row_mask] = EMPTY_GRAY

    img = Image.fromarray(canvas, "RGBA")
    scale = OUT_HEIGHT / h
    img = img.resize((max(1, round(w * scale)), OUT_HEIGHT), Image.LANCZOS)
    img.save(out_path)
    print(f"wrote {out_path} ({img.width}x{img.height})")


def main():
    mask = load_mask()
    for level in LEVELS:
        render(mask, level, SCRIPT_DIR / f"icon-{level}.png")


if __name__ == "__main__":
    main()
