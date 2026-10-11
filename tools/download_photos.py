#!/usr/bin/env python3
"""Optional: download all photos into HSKPrep/BundledPhotos so the app works fully offline
from the first launch. Run on your Mac (needs internet):

    python3 tools/download_photos.py
    xcodegen generate

Photos are the lead images of English Wikipedia articles (Wikimedia Commons, free licences).
Author and licence of each photo are written to HSKPrep/BundledPhotos/CREDITS.txt.
Without this step the app downloads photos itself and caches them.
"""
import json
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "HSKPrep" / "BundledPhotos"
UA = {"User-Agent": "HSKPrep/1.0 (iOS study app; https://github.com/RamziAbid91/HSKprep)"}


def get(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        return r.read()


def key(title: str) -> str:
    return title.replace(" ", "_").replace("(", "").replace(")", "")


def main():
    titles = sorted(set(json.loads((ROOT / "HSKPrep" / "Photos.json").read_text()).values()))
    OUT.mkdir(exist_ok=True)
    credits = []
    for t in titles:
        try:
            summary = json.loads(get("https://en.wikipedia.org/api/rest_v1/page/summary/" + urllib.parse.quote(t.replace(" ", "_"))))
            src = (summary.get("thumbnail") or summary.get("originalimage") or {}).get("source")
            if not src:
                print("no photo:", t); continue
            (OUT / f"{key(t)}.jpg").write_bytes(get(src))
            # Author + licence from Commons
            file_name = urllib.parse.unquote(src.split("/")[-1])
            if "px-" in file_name:
                file_name = file_name.split("px-", 1)[1]
            meta = json.loads(get("https://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=extmetadata&format=json&titles=File:" + urllib.parse.quote(file_name)))
            info = next(iter(meta["query"]["pages"].values())).get("imageinfo", [{}])[0].get("extmetadata", {})
            artist = info.get("Artist", {}).get("value", "unknown")
            lic = info.get("LicenseShortName", {}).get("value", "see file page")
            credits.append(f"{t}: File:{file_name} — {artist} — {lic} — https://commons.wikimedia.org/wiki/File:{urllib.parse.quote(file_name)}")
            print("ok:", t)
        except Exception as e:  # keep going
            print("failed:", t, e)
    (OUT / "CREDITS.txt").write_text("\n".join(credits) + "\n")


if __name__ == "__main__":
    main()
