#!/usr/bin/env python3
"""Generate natural Mandarin audio for the app with Azure AI Speech (neural voices).

What it records
  • every vocabulary word and example sentence (Vocabulary.json)
  • every grammar example (Grammar*.swift)
  • every listening dialogue / passage line with a man's or woman's voice, the spoken
    exam questions ("问：…"), and the reading texts (ExamContent.json)

Files go to HSKPrep/Audio/<key>.mp3 plus HSKPrep/Audio/manifest.json. The app plays these
automatically and uses the iPhone voice for anything that has no recording.

Setup (once)
  1. Create a free Azure account: https://azure.microsoft.com/free
  2. In the Azure portal create a "Speech service" resource (Free F0 tier is enough:
     500,000 characters per month; this project needs about 30,000).
  3. Copy KEY 1 and the Region (e.g. eastus) from the resource's "Keys and Endpoint" page.

Run (on your Mac, in the project folder)
  export AZURE_SPEECH_KEY="paste-key-here"
  export AZURE_SPEECH_REGION="eastus"
  python3 tools/generate_audio.py --dry-run     # shows how much will be recorded
  python3 tools/generate_audio.py --limit 5     # try 5 recordings first, listen to them
  python3 tools/generate_audio.py               # everything (safe to stop and re-run: it resumes)
  xcodegen generate

The free tier allows ~20 requests per minute, so a full run takes about 1–1.5 hours.
Never commit your key: it's read from the environment only.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "HSKPrep"
OUT = APP / "Audio"

DEFAULT_VOICES = {
    "main": "zh-CN-XiaoxiaoNeural",    # words, sentences, narrator, exam questions
    "female": "zh-CN-XiaoxiaoNeural",  # 女 in dialogues
    "male": "zh-CN-YunxiNeural",       # 男 in dialogues
}

# Single characters with several readings: tell Azure which one (SAPI pinyin with tone numbers).
POLYPHONIC = set("了的得地着还长好只种教为要少都会和分差吧啊呢吗个一不那哪数行重觉便空干发难看")
TONES = {"ā": ("a", 1), "á": ("a", 2), "ǎ": ("a", 3), "à": ("a", 4), "ē": ("e", 1), "é": ("e", 2), "ě": ("e", 3),
         "è": ("e", 4), "ī": ("i", 1), "í": ("i", 2), "ǐ": ("i", 3), "ì": ("i", 4), "ō": ("o", 1), "ó": ("o", 2),
         "ǒ": ("o", 3), "ò": ("o", 4), "ū": ("u", 1), "ú": ("u", 2), "ǔ": ("u", 3), "ù": ("u", 4), "ǖ": ("v", 1),
         "ǘ": ("v", 2), "ǚ": ("v", 3), "ǜ": ("v", 4), "ü": ("v", 0)}


def key(voice: str, text: str) -> str:
    """Must match RecordedAudio.key in Services.swift."""
    return hashlib.sha256(f"{voice}|{text}".encode("utf-8")).hexdigest()[:20]


def numbered_pinyin(syllable: str) -> str:
    tone, out = 5, ""
    for ch in syllable.lower():
        if ch in TONES:
            base, t = TONES[ch]
            out += base
            if t:
                tone = t
        elif ch.isalpha():
            out += ch
    return f"{out} {tone}"


# ── Collect everything the app speaks ───────────────────────────────────

def collect() -> dict[tuple[str, str], str | None]:
    """{(role, text): phoneme-or-None}"""
    items: dict[tuple[str, str], str | None] = {}

    def add(role, text, phoneme=None):
        text = (text or "").strip()
        if text:
            items.setdefault((role, text), phoneme)

    vocab = json.loads((APP / "Vocabulary.json").read_text())
    for w in vocab:
        ph = None
        if len(w["hanzi"]) == 1 and w["hanzi"] in POLYPHONIC and " " not in w["pinyin"]:
            ph = numbered_pinyin(w["pinyin"])
        add("main", w["hanzi"], ph)
        add("main", w.get("example"))

    for swift in APP.glob("Grammar*.swift"):
        for m in re.finditer(r'chinese: "([^"]+)"', swift.read_text()):
            add("main", m.group(1))

    content = json.loads((APP / "ExamContent.json").read_text())
    role_of = {"M": "male", "F": "female"}
    for item in content["listening"]:
        for line in item["lines"]:
            add(role_of.get(line["speaker"], "main"), line["text"])
        if item.get("question"):
            add("main", "问：" + item["question"])
    for r in content["reading"]:
        if r["kind"] == "cloze":
            add("main", r["text"].replace("＿＿", r["options"][r["answer"]]))
        else:
            add("main", r["text"])
        if r.get("reply"):
            add("main", r["reply"])
        if r.get("question"):
            add("main", "问：" + r["question"])

    # Fixed phrases used in the app (tone chart, settings samples)
    for t in ["妈", "麻", "马", "骂", "我每天早上七点起床，然后去学校学习汉语。"]:
        add("main", t)
    add("male", "你好，你叫什么名字？")
    add("female", "我叫王丽，很高兴认识你。")
    return items


# ── Azure ───────────────────────────────────────────────────────────────

def synthesize(text: str, voice: str, phoneme: str | None, region: str, api_key: str) -> bytes:
    body = escape(text)
    if phoneme:
        body = f'<phoneme alphabet="sapi" ph="{phoneme}">{body}</phoneme>'
    ssml = (f"<speak version='1.0' xml:lang='zh-CN'><voice name='{voice}'>"
            f"<prosody rate='-5%'>{body}</prosody></voice></speak>")
    req = urllib.request.Request(
        f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1",
        data=ssml.encode("utf-8"), method="POST",
        headers={"Ocp-Apim-Subscription-Key": api_key, "Content-Type": "application/ssml+xml",
                 "X-Microsoft-OutputFormat": "audio-24khz-48kbitrate-mono-mp3", "User-Agent": "HSKPrep"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true", help="only count recordings and characters")
    ap.add_argument("--limit", type=int, default=0, help="record at most N new files (for a test)")
    ap.add_argument("--main-voice", default=DEFAULT_VOICES["main"])
    ap.add_argument("--female-voice", default=DEFAULT_VOICES["female"])
    ap.add_argument("--male-voice", default=DEFAULT_VOICES["male"])
    ap.add_argument("--prune", action="store_true", help="delete mp3 files that are no longer used")
    args = ap.parse_args()

    voices = {"main": args.main_voice, "female": args.female_voice, "male": args.male_voice}
    items = collect()
    # Same voice + same text = one file.
    jobs: dict[str, tuple[str, str, str | None]] = {}
    for (role, text), ph in items.items():
        jobs.setdefault(key(voices[role], text), (voices[role], text, ph))

    OUT.mkdir(exist_ok=True)
    todo = {k: v for k, v in jobs.items() if not (OUT / f"{k}.mp3").exists()}
    chars = sum(len(t) for _, t, _ in todo.values())
    print(f"{len(jobs)} recordings needed, {len(jobs) - len(todo)} already done, "
          f"{len(todo)} to record ({chars:,} characters).")
    if args.dry_run:
        return

    api_key = os.environ.get("AZURE_SPEECH_KEY")
    region = os.environ.get("AZURE_SPEECH_REGION")
    if not api_key or not region:
        sys.exit("Set AZURE_SPEECH_KEY and AZURE_SPEECH_REGION first (see the top of this file).")

    done = 0
    for k, (voice, text, ph) in todo.items():
        if args.limit and done >= args.limit:
            break
        for attempt in range(6):
            try:
                audio = synthesize(text, voice, ph, region, api_key)
                (OUT / f"{k}.mp3").write_bytes(audio)
                done += 1
                print(f"[{done}/{len(todo)}] {voice.split('-')[2]}: {text[:40]}")
                break
            except urllib.error.HTTPError as e:
                if e.code == 429:   # free tier: too many requests per minute — wait and retry
                    wait = int(e.headers.get("Retry-After") or 10)
                    print(f"  rate limit, waiting {wait}s…")
                    time.sleep(wait)
                    continue
                if e.code in (401, 403):
                    sys.exit("Azure refused the key — check AZURE_SPEECH_KEY and AZURE_SPEECH_REGION.")
                if ph and e.code == 400:   # phoneme not accepted: record without it
                    ph = None
                    continue
                print(f"  HTTP {e.code} for {text!r}: {e.read()[:200]!r}")
                break
            except (urllib.error.URLError, TimeoutError) as e:
                print(f"  network error ({e}), retrying…")
                time.sleep(5)

    if args.prune:
        removed = 0
        for f in OUT.glob("*.mp3"):
            if f.stem not in jobs:
                f.unlink(); removed += 1
        print(f"Removed {removed} unused files.")

    present = sum(1 for k in jobs if (OUT / f"{k}.mp3").exists())
    (OUT / "manifest.json").write_text(json.dumps({"voices": voices, "count": present}, indent=1) + "\n")
    print(f"Done. {present}/{len(jobs)} recordings in HSKPrep/Audio. Now run: xcodegen generate")


if __name__ == "__main__":
    main()
