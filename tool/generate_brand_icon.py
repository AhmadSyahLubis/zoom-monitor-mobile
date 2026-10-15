"""Export the Monitor monogram to launcher icon sizes."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "icons"
SIZE = 1024
SCALE = 4
BACKGROUND = "#182640"
PAPER = "#F5F8FE"
ACCENT = "#94B4FA"


def make_icon(transparent: bool) -> Image.Image:
    canvas = Image.new(
        "RGBA",
        (SIZE * SCALE, SIZE * SCALE),
        (0, 0, 0, 0) if transparent else BACKGROUND,
    )
    draw = ImageDraw.Draw(canvas)
    def segment(points: list[tuple[int, int]], color: str, width: int = 82) -> None:
        scaled = [(x * SCALE, y * SCALE) for x, y in points]
        draw.line(scaled, fill=color, width=width * SCALE, joint="curve")
        radius = width * SCALE // 2
        for x, y in (scaled[0], scaled[-1]):
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)

    segment([(258, 712), (258, 326), (512, 542)], PAPER)
    segment([(766, 712), (766, 326)], PAPER)
    segment([(512, 542), (766, 326)], ACCENT)
    lens_x, lens_y = 512 * SCALE, 532 * SCALE
    outer = 53 * SCALE
    inner = 28 * SCALE
    draw.ellipse(
        (lens_x - outer, lens_y - outer, lens_x + outer, lens_y + outer),
        fill=ACCENT,
    )
    draw.ellipse(
        (lens_x - inner, lens_y - inner, lens_x + inner, lens_y + inner),
        fill=BACKGROUND if not transparent else (0, 0, 0, 0),
    )
    return canvas.resize((SIZE, SIZE), Image.Resampling.LANCZOS)


OUT.mkdir(parents=True, exist_ok=True)
make_icon(False).convert("RGB").save(OUT / "zoom_monitor_app_icon.png", optimize=True)
make_icon(True).save(OUT / "zoom_monitor_adaptive_foreground.png", optimize=True)
