"""watchOS app icon: the WikiRadar radar scope at 1024px, full-bleed.

Adapted from the Pebble repo's store-assets/make_assets.py; watchOS masks
the square to a circle itself, so the artwork fills the canvas and keeps
all elements inside the inscribed circle.
"""
import math
import os
from PIL import Image, ImageDraw

CERULEAN = (0, 170, 255)
SIZE = 1024

img = Image.new('RGBA', (SIZE, SIZE), CERULEAN + (255,))
c = SIZE / 2
r = SIZE * 0.38
ring_w = 50
thin = ring_w // 2
fg = (255, 255, 255, 255)
faint = (255, 255, 255, 110)

# Overlay 1: crosshairs and inner range rings (translucent elements are
# composited; drawing directly would punch low-alpha holes in the fill)
ov = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
od = ImageDraw.Draw(ov)
od.line([c - r, c, c + r, c], fill=faint, width=thin)
od.line([c, c - r, c, c + r], fill=faint, width=thin)
for ring in (0.55, 0.78):
    od.ellipse([c - r * ring, c - r * ring, c + r * ring, c + r * ring],
               outline=faint, width=thin)
img = Image.alpha_composite(img, ov)

# Overlay 2: sweep wedge with fading trail and a bright leading edge
ov = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
od = ImageDraw.Draw(ov)
for spread, alpha in ((55, 55), (30, 100)):
    od.pieslice([c - r, c - r, c + r, c + r],
                start=-60 - spread, end=-60, fill=(255, 255, 255, alpha))
edge = math.radians(-60)
od.line([c, c, c + r * math.cos(edge), c + r * math.sin(edge)],
        fill=fg, width=thin)
img = Image.alpha_composite(img, ov)

# Opaque elements straight onto the result
d = ImageDraw.Draw(img)
d.ellipse([c - r, c - r, c + r, c + r], outline=fg, width=ring_w)
cd = SIZE // 26
d.ellipse([c - cd, c - cd, c + cd, c + cd], fill=fg)
# Blips in the open annuli between rings, on diagonals clear of crosshairs
for ang, dist in ((-140, 0.13), (35, 0.25), (115, 0.34)):
    a = math.radians(ang)
    bx = c + dist * SIZE * math.cos(a)
    by = c + dist * SIZE * math.sin(a)
    br = SIZE // 22
    d.ellipse([bx - br, by - br, bx + br, by + br], fill=fg)

out = os.path.join(os.path.dirname(__file__), '..', 'WikiRadar',
                   'Assets.xcassets', 'AppIcon.appiconset', 'icon.png')
img.convert('RGB').save(os.path.normpath(out))
print('icon written')
