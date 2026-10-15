"""Rasterize the linked-spaces brand mark for Flutter launcher assets."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "icons"
SIZE = 1024
SCALE = 4
BACKGROUND = "#183B36"
IVORY = "#F6F1E7"
MINT = "#A9DBC1"


def make_icon(transparent: bool) -> Image.Image:
    canvas = Image.new(
        "RGBA",
        (SIZE * SCALE, SIZE * SCALE),
        (0, 0, 0, 0) if transparent else BACKGROUND,
    )
    draw = ImageDraw.Draw(canvas)
    for x, y, color in ((252, 250, IVORY), (364, 365, MINT)):
        draw.rounded_rectangle(
            (x * SCALE, y * SCALE, (x + 408) * SCALE, (y + 408) * SCALE),
            radius=98 * SCALE,
            outline=color,
            width=76 * SCALE,
        )
    return canvas.resize((SIZE, SIZE), Image.Resampling.LANCZOS)


make_icon(False).convert("RGB").save(OUT / "zoom_monitor_app_icon.png", optimize=True)
make_icon(True).save(OUT / "zoom_monitor_adaptive_foreground.png", optimize=True)
