#!/usr/bin/env python3
"""Icon designs v2. Usage: python3 tools/make_icons_v2.py [ink|lantern|bubble] [--install]
Without --install it writes previews to the given folder only."""
from __future__ import annotations
import math, random, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

S = 1024
SERIF = "/usr/share/fonts/opentype/noto/NotoSerifCJK-Black.ttc"
SANS = "/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc"
SC = 2  # simplified-Chinese face inside the Noto CJK collections


def F(path, size):
    return ImageFont.truetype(path, size, index=SC)


def gradient(c1, c2, angle=90):
    """Linear gradient; angle 90 = top→bottom, 45 = top-left→bottom-right."""
    g = Image.new("RGB", (S, S))
    px = g.load()
    a = math.radians(angle)
    dx, dy = math.cos(a), math.sin(a)
    proj = [x * dx + y * dy for x, y in ((0, 0), (S, 0), (0, S), (S, S))]
    lo, hi = min(proj), max(proj)
    for y in range(S):
        for x in range(S):
            t = ((x * dx + y * dy) - lo) / (hi - lo)
            px[x, y] = tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))
    return g


def text_center(draw, cx, cy, s, font, fill):
    b = draw.textbbox((0, 0), s, font=font)
    draw.text((cx - (b[2] - b[0]) / 2 - b[0], cy - (b[3] - b[1]) / 2 - b[1]), s, font=font, fill=fill)


def glyph_layer(s, font, cx, cy, fill):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    text_center(ImageDraw.Draw(layer), cx, cy, s, font, fill)
    return layer


def shadow(layer, blur, offset, color):
    a = layer.split()[3].filter(ImageFilter.GaussianBlur(blur))
    sh = Image.new("RGBA", (S, S), color)
    sh.putalpha(a.point(lambda v: v * color[3] // 255))
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(sh, offset, sh)
    return out


# ── A. Ink & paper ─────────────────────────────────────────────
def ink():
    random.seed(7)
    img = gradient((252, 246, 232), (238, 226, 200), 60).convert("RGBA")
    # rice-paper fibres
    fib = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(fib)
    for _ in range(900):
        x, y = random.randint(0, S), random.randint(0, S)
        L, a = random.randint(8, 40), random.uniform(0, math.pi)
        d.line((x, y, x + L * math.cos(a), y + L * math.sin(a)), fill=(150, 120, 80, random.randint(10, 28)), width=2)
    img.alpha_composite(fib)
    # soft ink wash circle behind the character
    wash = Image.new("L", (S, S), 0)
    ImageDraw.Draw(wash).ellipse((150, 120, 870, 840), fill=60)
    wash = wash.filter(ImageFilter.GaussianBlur(90))
    img.paste((40, 40, 48), (0, 0), wash)
    # big brush character 学 (study)
    g = glyph_layer("学", F(SERIF, 620), 500, 470, (24, 22, 28, 255))
    img.alpha_composite(shadow(g, 6, (6, 8), (0, 0, 0, 70)))
    img.alpha_composite(g)
    # red seal stamp with HSK
    seal = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(seal)
    x0, y0, w = 640, 700, 250
    sd.rounded_rectangle((x0, y0, x0 + w, y0 + w), radius=36, fill=(196, 30, 36, 245))
    sd.rounded_rectangle((x0 + 18, y0 + 18, x0 + w - 18, y0 + w - 18), radius=24, outline=(255, 236, 220, 255), width=8)
    text_center(sd, x0 + w / 2, y0 + w / 2 - 4, "HSK", F(SANS, 92), (255, 240, 228, 255))
    # stamp texture: knock out random specks
    specks = Image.new("L", (S, S), 255)
    spd = ImageDraw.Draw(specks)
    for _ in range(90):
        x, y = random.randint(x0, x0 + w), random.randint(y0, y0 + w)
        r = random.randint(1, 5)
        spd.ellipse((x - r, y - r, x + r, y + r), fill=random.randint(140, 210))
    seal.putalpha(ImageChops.multiply(seal.split()[3], specks))
    seal = seal.rotate(-6, center=(x0 + w / 2, y0 + w / 2), resample=Image.BICUBIC)
    img.alpha_composite(seal)
    return img


# ── B. Lantern night ───────────────────────────────────────────
def lantern():
    random.seed(3)
    img = gradient((22, 24, 62), (70, 20, 60), 70).convert("RGBA")
    # stars
    st = ImageDraw.Draw(img)
    for _ in range(70):
        x, y, r = random.randint(0, S), random.randint(0, 420), random.choice([1, 1, 2, 3])
        st.ellipse((x - r, y - r, x + r, y + r), fill=(255, 235, 200, random.randint(90, 200)))
    cx, cy, R = 512, 540, 330
    # glow
    glow = Image.new("L", (S, S), 0)
    ImageDraw.Draw(glow).ellipse((cx - R - 90, cy - R - 90, cx + R + 90, cy + R + 90), fill=200)
    img.paste((255, 120, 60), (0, 0), glow.filter(ImageFilter.GaussianBlur(110)))
    # lantern body: radial red→orange
    body = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    for i in range(R, 0, -2):
        t = i / R
        c = (int(250 - 40 * t), int(140 - 100 * t), int(60 - 30 * t), 255)
        bd.ellipse((cx - i * 0.92, cy - i, cx + i * 0.92, cy + i), fill=c)
    img.alpha_composite(body)
    # ribs
    d = ImageDraw.Draw(img)
    for k in (-0.62, -0.3, 0.3, 0.62):
        rx = R * 0.92 * abs(k)
        d.arc((cx - rx, cy - R, cx + rx, cy + R), 90 if k > 0 else 270, 270 if k > 0 else 90, fill=(150, 30, 20, 120), width=6)
    # caps + tassel
    gold = (246, 196, 92, 255)
    d.rounded_rectangle((cx - 120, cy - R - 40, cx + 120, cy - R + 18), radius=14, fill=gold)
    d.rounded_rectangle((cx - 120, cy + R - 18, cx + 120, cy + R + 40), radius=14, fill=gold)
    d.line((cx, cy - R - 40, cx, 60), fill=gold, width=8)
    for i in range(-3, 4):
        d.line((cx + i * 9, cy + R + 40, cx + i * 12, cy + R + 150), fill=(220, 40, 40, 255), width=6)
    # character
    g = glyph_layer("汉", F(SERIF, 380), cx, cy + 6, (255, 246, 228, 255))
    img.alpha_composite(shadow(g, 10, (0, 8), (120, 20, 0, 160)))
    img.alpha_composite(g)
    return img


# ── C. Speech bubble ───────────────────────────────────────────
def bubble():
    img = gradient((236, 64, 52), (176, 18, 52), 45).convert("RGBA")
    # soft shapes
    deco = Image.new("L", (S, S), 0)
    dd = ImageDraw.Draw(deco)
    dd.ellipse((-200, -260, 560, 420), fill=50)
    dd.ellipse((560, 640, 1240, 1300), fill=40)
    img.paste((255, 255, 255), (0, 0), deco.filter(ImageFilter.GaussianBlur(40)))
    # bubble
    b = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(b)
    bd.rounded_rectangle((170, 190, 854, 760), radius=150, fill=(255, 252, 246, 255))
    bd.polygon([(300, 720), (250, 880), (440, 750)], fill=(255, 252, 246, 255))
    img.alpha_composite(shadow(b, 24, (0, 22), (90, 0, 20, 120)))
    img.alpha_composite(b)
    d = ImageDraw.Draw(img)
    # character + tone mark
    text_center(d, 512, 470, "你好", F(SERIF, 250), (200, 28, 44, 255))
    text_center(d, 512, 650, "nǐ hǎo", F(SANS, 84), (230, 150, 60, 255))
    # sound waves
    for i, r in enumerate((60, 100, 140)):
        d.arc((790 - r, 250 - r, 790 + r, 250 + r), 300, 360, fill=(255, 230, 200, 230 - i * 50), width=14)
    return img


STYLES = {"ink": ink, "lantern": lantern, "bubble": bubble}

if __name__ == "__main__":
    style = sys.argv[1]
    img = STYLES[style]().convert("RGB")
    if "--install" in sys.argv:
        root = Path(__file__).resolve().parent.parent / "HSKPrep" / "Assets.xcassets"
        img.save(root / "AppIcon.appiconset" / "AppIcon.png")
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, S, S), radius=230, fill=255)
        logo = img.convert("RGBA"); logo.putalpha(mask)
        logo.resize((512, 512), Image.LANCZOS).save(root / "Logo.imageset" / "Logo.png")
        print("installed", style)
    else:
        img.save(sys.argv[2])
