#!/usr/bin/env python3
"""Generates the FootRDC launcher icons (Android and iOS) from one transparent square logo, keeping every existing file
name and size. The logo is never redrawn: it is only scaled (Lanczos) and placed on a white background.

    python3 tool/generate_launcher_icons.py "path/to/Logo Foot RDC_1.png"

Android: adaptive icon = white background colour + foreground (108 dp canvas, logo 64 dp wide so even its outermost
bump stays inside the 72 dp visible circle of any mask) ; legacy ic_launcher (white rounded square) and
ic_launcher_round (white circle) for launchers without adaptive icons. iOS: opaque white squares, logo at 80 % (App Store
icons must not be transparent). Notification icons are not touched.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
WHITE = (255, 255, 255, 255)


def logo(src: Path) -> Image.Image:
    image = Image.open(src).convert('RGBA')
    if image.size[0] != image.size[1]:
        sys.exit(f'The logo must be square, got {image.size}.')
    return image


def placed(source: Image.Image, canvas: int, width: float, background=None, shape='square') -> Image.Image:
    """The logo scaled to `width` (fraction of the canvas), centred; on a background shape when given."""
    out = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    if background:
        mask = Image.new('L', (canvas * 4, canvas * 4), 0)
        draw = ImageDraw.Draw(mask)
        if shape == 'circle':
            draw.ellipse((0, 0, canvas * 4 - 1, canvas * 4 - 1), fill=255)
        elif shape == 'rounded':
            draw.rounded_rectangle((0, 0, canvas * 4 - 1, canvas * 4 - 1), radius=int(canvas * 4 * 0.18), fill=255)
        else:
            draw.rectangle((0, 0, canvas * 4 - 1, canvas * 4 - 1), fill=255)
        out.paste(Image.new('RGBA', (canvas, canvas), background), (0, 0), mask.resize((canvas, canvas), Image.LANCZOS))
    size = round(canvas * width)
    scaled = source.resize((size, size), Image.LANCZOS)
    offset = (canvas - size) // 2
    out.alpha_composite(scaled, (offset, offset))
    return out


def save(image: Image.Image, path: Path, opaque=False):
    if opaque:
        flat = Image.new('RGB', image.size, WHITE[:3])
        flat.paste(image, (0, 0), image)
        flat.save(path, optimize=True)
    else:
        image.save(path, optimize=True)


def main():
    source = logo(Path(sys.argv[1]))
    res = ROOT / 'android/app/src/main/res'
    density = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, scale in density.items():
        folder = res / f'mipmap-{name}'
        save(placed(source, round(108 * scale), 64 / 108), folder / 'ic_launcher_foreground.png')
        save(placed(source, round(48 * scale), 0.80, WHITE, 'rounded'), folder / 'ic_launcher.png')
        save(placed(source, round(48 * scale), 0.78, WHITE, 'circle'), folder / 'ic_launcher_round.png')
    save(placed(source, 36, 0.80, WHITE, 'rounded'), res / 'mipmap-ldpi/ic_launcher.png')
    (res / 'values/ic_launcher_background.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#FFFFFF</color>\n</resources>\n')

    catalog = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    contents = json.loads((catalog / 'Contents.json').read_text())
    for entry in contents['images']:
        if 'filename' not in entry:
            continue
        points = float(entry['size'].split('x')[0])
        pixels = round(points * int(entry['scale'].rstrip('x')))
        save(placed(source, pixels, 0.80, WHITE), catalog / entry['filename'], opaque=True)
    for extra in catalog.glob('ItunesArtwork*.png'):
        save(placed(source, Image.open(extra).size[0], 0.80, WHITE), extra, opaque=True)
    print('Launcher icons written.')


if __name__ == '__main__':
    main()
