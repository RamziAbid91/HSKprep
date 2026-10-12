#!/usr/bin/env python3
"""Draws the app icon (1024×1024) and the in-app logo. Run: python3 tools/make_logo.py
Font: Noto Serif/Sans CJK (SIL Open Font License)."""
from __future__ import annotations
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "HSKPrep" / "Assets.xcassets" / "AppIcon.appiconset"
LOGO_DIR = ROOT / "HSKPrep" / "Assets.xcassets" / "Logo.imageset"
SERIF = "/usr/share/fonts/opentype/noto/NotoSerifCJK-Black.ttc"
SANS = "/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc"
S = 1024
RED_TOP, RED_BOTTOM = (226, 52, 48), (168, 18, 30)
GOLD = (246, 196, 92)
CREAM = (255, 248, 236)


def font(path, size, index=2):  # index 2 = SC (simplified Chinese) in the Noto CJK collections
    try:
        return ImageFont.truetype(path, size, index=index)
    except OSError:
        return ImageFont.truetype("/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc", size, index=index)


def draw_icon(transparent=False) -> Image.Image:
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    if not transparent:
        # Vertical red gradient
        bg = Image.new("RGB", (S, S))
        px = bg.load()
        for y in range(S):
            t = y / (S - 1)
            c = tuple(int(RED_TOP[i] * (1 - t) + RED_BOTTOM[i] * t) for i in range(3))
            for x in range(S):
                px[x, y] = c
        img.paste(bg)
        # Soft light in the top-left corner
        glow = Image.new("L", (S, S), 0)
        ImageDraw.Draw(glow).ellipse((-300, -300, 620, 620), fill=70)
        glow = glow.filter(ImageFilter.GaussianBlur(120))
        img.paste((255, 255, 255), (0, 0), glow)

    d = ImageDraw.Draw(img)
    # Seal ring (like a Chinese name stamp)
    cx, cy, r = S // 2, 452, 330
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=GOLD, width=22)
    d.ellipse((cx - r + 40, cy - r + 40, cx + r - 40, cy + r - 40), outline=(*GOLD, 120), width=6)
    # Little ticks around the ring
    for k in range(24):
        a = k / 24 * 2 * math.pi
        if math.sin(a) > 0.55:   # leave room for the HSK ribbon
            continue
        x1, y1 = cx + (r + 24) * math.cos(a), cy + (r + 24) * math.sin(a)
        x2, y2 = cx + (r + 44) * math.cos(a), cy + (r + 44) * math.sin(a)
        d.line((x1, y1, x2, y2), fill=(*GOLD, 160), width=6)

    # 汉 = Chinese (as in 汉语)
    f = font(SERIF, 430)
    box = d.textbbox((0, 0), "汉", font=f)
    w, h = box[2] - box[0], box[3] - box[1]
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((cx - w / 2 - box[0] + 8, cy - h / 2 - box[1] + 14), "汉", font=f, fill=(90, 0, 10, 140))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    d = ImageDraw.Draw(img)
    d.text((cx - w / 2 - box[0], cy - h / 2 - box[1]), "汉", font=f, fill=CREAM)

    # HSK ribbon
    ft = ImageFont.truetype(SANS, 150, index=2)
    label = "HSK"
    tb = d.textbbox((0, 0), label, font=ft)
    tw = tb[2] - tb[0]
    y = 830
    d.rounded_rectangle((cx - tw / 2 - 50, y - 18, cx + tw / 2 + 50, y + 168), radius=40, fill=GOLD)
    d.text((cx - tw / 2 - tb[0], y - tb[1] + 6), label, font=ft, fill=(150, 16, 28))
    return img


def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    LOGO_DIR.mkdir(parents=True, exist_ok=True)
    icon = draw_icon().convert("RGB")      # App Store icons must not have transparency
    icon.save(ICON_DIR / "AppIcon.png")
    (ICON_DIR / "Contents.json").write_text('''{
  "images" : [
    { "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
''')
    # Logo for inside the app (rounded corners, transparent outside)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S, S), radius=230, fill=255)
    logo = draw_icon()
    logo.putalpha(mask)
    logo.resize((512, 512), Image.LANCZOS).save(LOGO_DIR / "Logo.png")
    (LOGO_DIR / "Contents.json").write_text('''{
  "images" : [ { "filename" : "Logo.png", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
''')
    root = ROOT / "HSKPrep" / "Assets.xcassets" / "Contents.json"
    root.write_text('{\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n')
    print("Icon and logo written.")


if __name__ == "__main__":
    main()
