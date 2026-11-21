"""Builds the 1024x1024 App Store icon from docs/iSueca_logo.jpeg.

The logo arrives as a mock-up: a rounded navy card with a gold frame on a white
background. iOS applies its own mask, so we keep only the navy card, square it,
and paint the light corners outside the card with the card's own navy.
"""
import sys
from collections import deque
from PIL import Image, ImageFilter

SRC = "docs/iSueca_logo.jpeg"
OUT = "iSueca/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
LOGO_OUT = "iSueca/Resources/Assets.xcassets/AppLogo.imageset/AppLogo.png"


def lum(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def dark_bounds(im):
    px, (w, h) = im.load(), im.size
    rows = [y for y in range(h // 4, 3 * h // 4, 40)]
    cols = [x for x in range(w // 3, 2 * w // 3, 40)]
    left = min(next(x for x in range(w) if lum(px[x, y]) < 110) for y in rows)
    right = max(next(x for x in range(w - 1, -1, -1) if lum(px[x, y]) < 110) for y in rows)
    top = min(next(y for y in range(h) if lum(px[x, y]) < 110) for x in cols)
    bottom = max(next(y for y in range(h - 1, -1, -1) if lum(px[x, y]) < 110) for x in cols)
    return left, top, right, bottom


def main():
    im = Image.open(SRC).convert("RGB")
    left, top, right, bottom = dark_bounds(im)
    inset = 14
    side = min(right - left, bottom - top) - 2 * inset
    cx, cy = (left + right) // 2, (top + bottom) // 2
    box = (cx - side // 2, cy - side // 2, cx - side // 2 + side, cy - side // 2 + side)
    card = im.crop(box)

    # Navy of the card's frame, sampled along the middle of each edge.
    px = card.load()
    samples = [px[side // 2, 6], px[6, side // 2], px[side - 7, side // 2], px[side // 2, side - 7]]
    navy = tuple(sorted(s[i] for s in samples)[len(samples) // 2] for i in range(3))

    # Flood fill the light corner pixels (white background, gold frame) from each corner.
    mask = Image.new("L", card.size, 0)
    mpx = mask.load()
    limit = side // 4
    for sx, sy in [(0, 0), (side - 1, 0), (0, side - 1), (side - 1, side - 1)]:
        queue, seen = deque([(sx, sy)]), {(sx, sy)}
        while queue:
            x, y = queue.popleft()
            if abs(x - sx) > limit or abs(y - sy) > limit or lum(px[x, y]) < 90:
                continue
            mpx[x, y] = 255
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < side and 0 <= ny < side and (nx, ny) not in seen:
                    seen.add((nx, ny))
                    queue.append((nx, ny))
    mask = mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(2))
    card.paste(Image.new("RGB", card.size, navy), mask=mask)

    icon = card.resize((1024, 1024), Image.LANCZOS).convert("RGB")
    icon.save(OUT, optimize=True)
    icon.resize((512, 512), Image.LANCZOS).save(LOGO_OUT, optimize=True)
    print("bounds", (left, top, right, bottom), "side", side, "navy", navy)


if __name__ == "__main__":
    sys.exit(main())
