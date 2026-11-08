#!/usr/bin/env python3
"""Writes Thundermist's app icon, Thundermist/Thundermist.icon.

The icon is a waterfall seen close up: open land and a river above the lip, a
wide curtain of water over the cliffs, and mist rising where it lands. Light
mode shows it at golden hour and dark mode at afterglow, just after sunset.
Each scene is five full-canvas layers, sky, land, cliffs, fall and mist, so
macOS gives the icon its depth; the dark layers show only in dark mode.

Run it after changing a scene below; Scripts/install-thundermist.sh puts the
icon in place of Crest's when it builds.
"""

import json
import pathlib
import shutil
import sys

SIZE = 824  # the drawing's units; each layer scales them to the 1024 canvas
CENTER = SIZE / 2

# Where things sit, shared by both scenes.
HORIZON, LIP, HALF, BOTTOM, SPREAD, MIST = 110, 250, 215, 740, 22, 1.3
TREES = [(-70, 0.15), (-140, 0.4), (-230, 0.75), (-320, 0.55), (-380, 0.95),
         (75, 0.2), (150, 0.45), (240, 0.8), (330, 0.6), (385, 0.95)]

SCENES = {
    "Golden": dict(
        sky=("#f59a52", "#ffe2a8"), sun=("#fff3c4", 640, 62, 34), hill="#a88a5c",
        land=("#8aa63c", "#5b7a28"), river=("#c98a4a", "#ffd9a0"), tree="#4f6a20",
        rock=("#7a6250", "#4a3a30"), fall=("#fff8ec", "#f7d9b0"), streak="#e0b07a"),
    "Afterglow": dict(
        sky=("#2a2350", "#e0794a"), sun=("#ffd08a", 640, 118, 30), hill="#5a3f4f",
        land=("#3f4a2a", "#24301a"), river=("#5a3f5f", "#e8956a"), tree="#1f2a14",
        rock=("#3f3238", "#221a20"), fall=("#fde9dc", "#d9a08a"), streak="#b9786a"),
}


def gradient(name, colors):
    top, bottom = colors
    return (f'<linearGradient id="{name}" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>')


BLUR = ('<filter id="mist" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="16"/></filter>'
        '<filter id="soft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="30"/></filter>')


def sky(s):
    color, x, y, r = s["sun"]
    return ([gradient("sky", s["sky"]), BLUR],
            [f'<rect width="{SIZE}" height="{SIZE}" fill="url(#sky)"/>',
             f'<circle cx="{x}" cy="{y}" r="{r * 1.8}" fill="{color}" opacity=".35" filter="url(#soft)"/>',
             f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}"/>'])


def land(s):
    h, left, right = HORIZON, CENTER - HALF, CENTER + HALF
    shapes = [f'<path d="M0 {h + 8} Q120 {h - 46} 250 {h - 6} T520 {h - 10} T824 {h - 24} V{h + 20} H0 Z" fill="{s["hill"]}"/>',
              f'<rect y="{h}" width="{SIZE}" height="{LIP - h + 2}" fill="url(#land)"/>',
              f'<path d="M{CENTER - 18} {h} L{CENTER + 18} {h} L{right} {LIP} L{left} {LIP} Z" fill="url(#river)"/>']
    for t in (-0.45, 0.1, 0.55):
        shapes.append(f'<path d="M{CENTER + t * 14} {h + 8} L{CENTER + t * HALF * 0.9} {LIP - 6}" stroke="#ffffff" '
                      f'stroke-opacity=".45" stroke-width="5" stroke-linecap="round"/>')
    for offset, depth in TREES:
        x, y = CENTER + offset, h + (LIP - h) * depth + 4
        size = 14 + (46 - 14) * depth
        shapes.append(f'<rect x="{x - size * 0.12}" y="{y - size * 0.6}" width="{size * 0.24}" height="{size * 0.6}" fill="#4a3426"/>'
                      f'<circle cx="{x}" cy="{y - size * 1.1}" r="{size * 0.75}" fill="{s["tree"]}"/>')
    return [gradient("land", s["land"]), gradient("river", s["river"])], shapes


def cliffs(s):
    shapes = [f'<rect y="{LIP}" width="{SIZE}" height="{SIZE - LIP}" fill="url(#rock)"/>']
    for top, bottom in [(90, 110), (190, 170), (640, 660), (730, 712)]:
        shapes.append(f'<path d="M{top} {LIP + 30} L{bottom} {BOTTOM}" stroke="#000000" stroke-opacity=".18" '
                      f'stroke-width="10" stroke-linecap="round"/>')
    return [gradient("rock", s["rock"])], shapes


def fall(s):
    left, right = CENTER - HALF, CENTER + HALF
    shapes = [f'<path d="M{left} {LIP} C{left} {LIP - 14} {right} {LIP - 14} {right} {LIP} '
              f'L{right + SPREAD} {BOTTOM} H{left - SPREAD} Z" fill="url(#fall)"/>']
    count = int(2 * HALF / 42)
    for i in range(count):
        x = left + (i + 0.5) * (2 * HALF) / count
        color, opacity = ("#ffffff", 0.55) if i % 2 == 0 else (s["streak"], 0.35)
        shapes.append(f'<rect x="{x - 6}" y="{LIP + 12}" width="12" height="{BOTTOM - LIP - 30}" rx="6" '
                      f'fill="{color}" opacity="{opacity}"/>')
    return [gradient("fall", s["fall"])], shapes


def mist(s):
    puffs = [(CENTER - HALF - 70, BOTTOM + 46, 110), (CENTER - HALF * 0.4, BOTTOM + 26, 125),
             (CENTER + HALF * 0.4, BOTTOM + 26, 125), (CENTER + HALF + 70, BOTTOM + 46, 110),
             (CENTER, BOTTOM - 20 * MIST, 100)]
    # Icon Composer blurs single shapes but not groups, so each shape carries the filter.
    shapes = [f'<circle cx="{x}" cy="{y}" r="{r}" fill="#ffffff" filter="url(#mist)"/>' for x, y, r in puffs]
    shapes.append(f'<rect y="{BOTTOM + 60}" width="{SIZE}" height="{SIZE - BOTTOM}" fill="#ffffff" filter="url(#mist)"/>')
    for side in (-1, 1):
        shapes.append(f'<ellipse cx="{CENTER + side * (HALF + 40)}" cy="{BOTTOM - 120 * MIST}" rx="{58 * MIST}" '
                      f'ry="{120 * MIST}" fill="#ffffff" opacity=".6" filter="url(#soft)"/>')
    return [BLUR], shapes


LAYERS = [("Mist", mist), ("Fall", fall), ("Cliffs", cliffs), ("Land", land), ("Sky", sky)]  # top to bottom


def svg(definitions, shapes):
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 {SIZE} {SIZE}">'
            f'<defs>{"".join(definitions)}</defs>{"".join(shapes)}</svg>\n')


def layer(scene, part, dark):
    shown, hidden = (0, 1) if dark else (1, 0)
    return {
        "name": f"{scene}{part}",
        "image-name": f"{scene}{part}.svg",
        # Glass would rim each soft shape of the mist with a hard highlight.
        "glass": False,
        "fill-specializations": [{"value": "none"}, {"appearance": "dark", "value": "none"}],
        "opacity-specializations": [{"value": shown}, {"appearance": "dark", "value": hidden}],
    }


def write(bundle):
    if bundle.exists():
        shutil.rmtree(bundle)
    assets = bundle / "Assets"
    assets.mkdir(parents=True)
    layers = []
    for scene, colors in SCENES.items():
        dark = scene != "Golden"
        for part, draw in LAYERS:
            (assets / f"{scene}{part}.svg").write_text(svg(*draw(colors)), encoding="utf-8")
            layers.append(layer(scene, part, dark))
    # Dark layers sit above the light ones, as in Crest's icon; each shows in one appearance.
    layers.sort(key=lambda entry: not entry["name"].startswith("Afterglow"))
    icon = {
        "fill-specializations": [{"value": "none"}, {"appearance": "dark", "value": "none"}],
        "groups": [{"name": "Waterfall", "layers": layers, "shadow": {"kind": "neutral", "opacity": 0.5},
                    "specular": False, "translucency": {"enabled": False, "value": 0}}],
        "supported-platforms": {"squares": "shared"},
    }
    (bundle / "icon.json").write_text(json.dumps(icon, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    root = pathlib.Path(__file__).resolve().parents[1]
    write(pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else root / "Thundermist" / "Thundermist.icon")
