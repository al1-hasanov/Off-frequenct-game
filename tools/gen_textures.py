#!/usr/bin/env python3
"""Generate the light textures Off Frequency uses for darkness.

    python3 tools/gen_textures.py

textures/cone.png   flashlight beam. The apex is the image centre and the beam
                    points right, so a PointLight2D needs no offset: rotate it.
textures/glow.png   soft round light around Mara so she stays visible.
"""
import math
import os

from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures")


def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def cone(w=1024, h=512, half_angle=0.36, reach=500.0):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    px = img.load()
    cx, cy = w // 2, h // 2
    for y in range(h):
        for x in range(cx, w):
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            if d < 1:
                continue
            ang = abs(math.atan2(dy, dx))
            edge = 1.0 - smoothstep(half_angle * 0.55, half_angle, ang)
            fall = max(0.0, 1.0 - d / reach) ** 1.25
            core = 0.35 * (1.0 - smoothstep(0.0, half_angle * 0.5, ang)) * fall
            v = min(1.0, edge * fall + core)
            g = int(255 * v)
            px[x, y] = (g, g, g, 255)
    return img


def glow(size=256):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    px = img.load()
    c = size / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c) / c
            v = max(0.0, 1.0 - d) ** 2
            g = int(255 * v)
            px[x, y] = (g, g, g, 255)
    return img


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    cone().save(os.path.join(OUT, "cone.png"))
    glow().save(os.path.join(OUT, "glow.png"))
    print("wrote textures/cone.png, textures/glow.png")
