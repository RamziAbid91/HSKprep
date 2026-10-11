#!/usr/bin/env python3
"""Builds HSKPrep/Vocabulary.json.

Source word lists: tools/source/old{1,2,3}.json — HSK 2.0 lists from
https://github.com/drkameleon/complete-hsk-vocabulary (MIT License).

Existing entries in Vocabulary.json keep their IDs, pinyin, English and example
sentences (learner progress is keyed on the ID). New words get new IDs.

Usage:  python3 tools/build_vocab.py
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "HSKPrep" / "Vocabulary.json"
SRC = Path(__file__).resolve().parent / "source"

# Picture (emoji) for words that can be drawn. Used on flashcards and in
# picture-based exam questions.
EMOJI = {
    # HSK 1
    "爸爸": "👨", "妈妈": "👩", "杯子": "🥤", "北京": "🏯", "菜": "🥬", "茶": "🍵", "吃": "🍽️",
    "出租车": "🚕", "打电话": "📞", "电脑": "💻", "电视": "📺", "电影": "🎬", "读": "📖",
    "儿子": "👦", "饭馆": "🍜", "飞机": "✈️", "狗": "🐕", "喝": "🥤", "火车站": "🚉",
    "家": "🏠", "冷": "🥶", "猫": "🐈", "米饭": "🍚", "女儿": "👧", "朋友": "🧑‍🤝‍🧑",
    "苹果": "🍎", "钱": "💰", "热": "🥵", "商店": "🏪", "书": "📚", "水": "💧", "水果": "🍇",
    "睡觉": "😴", "说话": "🗣️", "天气": "🌤️", "听": "👂", "下雨": "🌧️", "写": "✍️",
    "学生": "🧑‍🎓", "学校": "🏫", "衣服": "👕", "医生": "🧑‍⚕️", "医院": "🏥", "椅子": "🪑",
    "中国": "🇨🇳", "桌子": "🪵", "字": "🔤", "坐": "🪑", "老师": "🧑‍🏫", "爱": "❤️",
    "大": "🐘", "小": "🐭", "漂亮": "💐", "先生": "🤵", "小姐": "👩‍💼", "看": "👀",
    "工作": "💼", "开": "🚗", "八": "8️⃣", "九": "9️⃣", "六": "6️⃣", "七": "7️⃣", "三": "3️⃣",
    "四": "4️⃣", "五": "5️⃣", "二": "2️⃣", "一": "1️⃣", "十": "🔟", "零": "0️⃣",
    "饭店": "🏨", "同学": "👫", "喜欢": "😍", "谢谢": "🙏", "再见": "👋", "对不起": "🙇",
    # HSK 2
    "白": "⚪", "报纸": "📰", "唱歌": "🎤", "船": "🚢", "打篮球": "🏀", "弟弟": "👦",
    "房间": "🛏️", "服务员": "🧑‍🍳", "高": "🦒", "哥哥": "👨", "公共汽车": "🚌",
    "黑": "⚫", "红": "🔴", "机场": "🛫", "鸡蛋": "🥚", "教室": "🏫", "姐姐": "👩",
    "咖啡": "☕", "考试": "📝", "快": "⚡", "快乐": "😄", "累": "😩", "旅游": "🧳",
    "慢": "🐢", "门": "🚪", "妹妹": "👧", "男人": "👨", "牛奶": "🥛", "女人": "👩",
    "跑步": "🏃", "票": "🎫", "起床": "⏰", "晴": "☀️", "生病": "🤒", "生日": "🎂",
    "手表": "⌚", "手机": "📱", "送": "🎁", "踢": "⚽", "跳舞": "💃", "玩": "🎮",
    "晚上": "🌙", "洗": "🧼", "西瓜": "🍉", "笑": "😂", "休息": "🛋️", "雪": "❄️",
    "眼睛": "👁️", "羊肉": "🐑", "药": "💊", "阴": "☁️", "游泳": "🏊", "鱼": "🐟",
    "运动": "🤸", "早上": "🌅", "丈夫": "🤵", "自行车": "🚲", "走": "🚶", "孩子": "🧒",
    "颜色": "🎨", "公司": "🏢", "宾馆": "🏨", "上班": "🧑‍💼",
    # HSK 3
    "阿姨": "👩", "矮": "🧍", "包": "👜", "饱": "😋", "鼻子": "👃", "比赛": "🏆",
    "冰箱": "🧊", "菜单": "📋", "草": "🌱", "超市": "🛒", "衬衫": "👔", "城市": "🏙️",
    "厨房": "🍳", "春": "🌸", "打扫": "🧹", "蛋糕": "🍰", "地铁": "🚇", "地图": "🗺️",
    "灯": "💡", "电梯": "🛗", "冬": "⛄", "动物": "🐾", "锻炼": "🏋️", "饿": "😫",
    "耳朵": "👂", "发烧": "🤒", "感冒": "🤧", "公园": "🌳", "果汁": "🧃", "河": "🏞️",
    "黑板": "🧑‍🏫", "护照": "🛂", "花": "🌷", "花园": "🏡", "画": "🎨", "黄": "🟡",
    "脚": "🦶", "结婚": "💒", "渴": "🥵", "空调": "❄️", "哭": "😢", "裤子": "👖",
    "筷子": "🥢", "蓝": "🔵", "礼物": "🎁", "脸": "🙂", "楼": "🏢", "绿": "🟢", "马": "🐎",
    "帽子": "🧢", "面包": "🍞", "面条": "🍜", "奶奶": "👵", "鸟": "🐦", "爬山": "🧗",
    "盘子": "🍽️", "胖": "🐷", "啤酒": "🍺", "葡萄": "🍇", "骑": "🚴", "铅笔": "✏️",
    "秋": "🍂", "裙子": "👗", "伞": "☂️", "上网": "🌐", "生气": "😠", "叔叔": "👨",
    "瘦": "🧍", "树": "🌳", "数学": "➗", "刷": "🪥", "司机": "🧑‍✈️", "太阳": "☀️",
    "糖": "🍬", "疼": "🤕", "体育": "🏅", "甜": "🍭", "头发": "💇", "图书馆": "🏛️",
    "腿": "🦵", "碗": "🥣", "洗手间": "🚻", "洗澡": "🛁", "夏": "🏖️", "香蕉": "🍌",
    "小心": "⚠️", "鞋": "👟", "新闻": "📰", "信": "✉️", "行李箱": "🧳", "熊猫": "🐼",
    "眼镜": "👓", "爷爷": "👴", "音乐": "🎵", "银行": "🏦", "游戏": "🎲", "月亮": "🌙",
    "云": "☁️", "照片": "🖼️", "照相机": "📷", "作业": "📒", "字典": "📕", "邻居": "🏘️",
    "客人": "🛎️", "经理": "👔", "校长": "🧑‍🏫", "年轻": "🧑", "老": "🧓", "蛋": "🥚",
}


# ── Picture clean-up ──
# Every picture must show ONE clear thing. Abstract words (big, fast, love…) and words that would
# share a photo with another word (older brother vs dad, grandma vs grandpa…) get no picture,
# so picture questions are never ambiguous.
NO_PICTURE = [
    "大", "小", "高", "矮", "胖", "瘦", "快", "慢", "热", "冷", "渴", "饿", "饱", "累", "爱", "喜欢", "漂亮",
    "快乐", "年轻", "老", "看", "听", "说话", "工作", "开", "送", "玩", "坐", "喝", "哥哥", "姐姐", "弟弟",
    "妹妹", "丈夫", "先生", "小姐", "爷爷", "奶奶", "阿姨", "叔叔", "校长", "经理", "同学", "上班", "客人",
    "新闻", "晴", "阴", "生病", "骑", "生日", "谢谢", "对不起", "再见", "小心", "疼",
]
for _w in NO_PICTURE:
    EMOJI.pop(_w, None)
EMOJI.update({
    "爸爸": "👨", "妈妈": "👩", "男人": "🧔", "女人": "👩‍🦰", "吃": "😋", "饭馆": "🍴", "水果": "🧺",
    "晚上": "🌃", "空调": "🌀", "树": "🌲", "颜色": "🌈", "夏": "🌻", "旅游": "🏖️", "教室": "📐",
    "楼": "🏬", "黑板": "🖍️", "笑": "😂", "哭": "😢", "生气": "😠", "字": "🀄", "盘子": "🍽️",
})

# Hand-checked pinyin/English for words with several readings (the source lists
# the readings in no particular order) or whose dictionary meaning isn't the HSK one.
OVERRIDES = {
    "大": ("dà", "big; large; old (age)"), "的": ("de", "(possessive / attributive particle)"),
    "点": ("diǎn", "o'clock; a little; point"), "东西": ("dōngxi", "thing; stuff"),
    "都": ("dōu", "all; both"), "读": ("dú", "to read; to study"),
    "多少": ("duōshao", "how many; how much"), "个": ("gè", "(general measure word)"),
    "好": ("hǎo", "good; well"), "喝": ("hē", "to drink"), "和": ("hé", "and; with"),
    "回": ("huí", "to return; to go back"), "会": ("huì", "can; know how to; will"),
    "几": ("jǐ", "how many; a few"), "家": ("jiā", "home; family"), "叫": ("jiào", "to be called; to call"),
    "看": ("kàn", "to look; to watch; to read"), "了": ("le", "(completed action / change particle)"),
    "里": ("lǐ", "inside; in"), "吗": ("ma", "(yes/no question particle)"),
    "没": ("méi", "not (have); did not"), "哪": ("nǎ", "which"), "那": ("nà", "that"),
    "呢": ("ne", "(particle: what about…?; ongoing action)"), "年": ("nián", "year"),
    "钱": ("qián", "money"), "日": ("rì", "day; date; sun"), "上": ("shàng", "up; on; above; last (week etc.)"),
    "少": ("shǎo", "few; little"), "岁": ("suì", "years old"), "听": ("tīng", "to listen; to hear"),
    "喂": ("wéi", "hello (on the phone)"), "怎么": ("zěnme", "how; why"), "坐": ("zuò", "to sit; to take (a bus etc.)"),
    "下": ("xià", "down; under; next (week etc.)"), "些": ("xiē", "some"), "一": ("yī", "one"),
    "吧": ("ba", "(suggestion particle)"), "便宜": ("piányi", "cheap"), "别": ("bié", "don't; other"),
    "得": ("de", "(particle: verb + 得 + degree)"), "告诉": ("gàosu", "to tell"), "给": ("gěi", "to give; for"),
    "还": ("hái", "still; also"), "好吃": ("hǎochī", "delicious"), "号": ("hào", "day of the month; number"),
    "累": ("lèi", "tired"), "离": ("lí", "away from (distance)"), "女人": ("nǚrén", "woman"),
    "妻子": ("qīzi", "wife"), "为": ("wèi", "for"), "要": ("yào", "to want; will; need to"),
    "长": ("cháng", "long"), "着": ("zhe", "(particle: ongoing state)"), "远": ("yuǎn", "far"),
    "张": ("zhāng", "(measure word for flat things); to open"), "向": ("xiàng", "towards"),
    "比": ("bǐ", "compared to; than"), "出": ("chū", "to go out; to come out"), "从": ("cóng", "from"),
    "错": ("cuò", "wrong; mistake"), "门": ("mén", "door; gate"), "路": ("lù", "road; route"),
    "元": ("yuán", "yuan (currency)"), "千": ("qiān", "thousand"), "题": ("tí", "question; problem"),
    "玩": ("wán", "to play; to have fun"), "笑": ("xiào", "to laugh; to smile"), "新": ("xīn", "new"),
    "也": ("yě", "also; too"), "阴": ("yīn", "cloudy; overcast"), "最": ("zuì", "most"),
    "把": ("bǎ", "(object marker); measure word for things with a handle"), "才": ("cái", "only then; just"),
    "差": ("chà", "poor; to be short of"), "地": ("de", "(particle: adverb + 地 + verb)"),
    "地方": ("dìfang", "place"), "分": ("fēn", "minute; point; cent; to divide"), "更": ("gèng", "more; even more"),
    "故事": ("gùshi", "story"), "关": ("guān", "to close; to turn off"), "过去": ("guòqù", "the past; to go over"),
    "角": ("jiǎo", "jiao (1/10 yuan); corner"), "教": ("jiāo", "to teach"), "难": ("nán", "difficult"),
    "鸟": ("niǎo", "bird"), "胖": ("pàng", "fat; chubby"), "骑": ("qí", "to ride (bike, horse)"),
    "只": ("zhǐ", "only; (measure word for animals: zhī)"), "种": ("zhǒng", "kind; type"),
    "万": ("wàn", "ten thousand"), "越": ("yuè", "the more… (越…越…)"), "云": ("yún", "cloud"),
    "关系": ("guānxi", "relationship"), "一边": ("yìbiān", "one side; while (一边…一边…)"),
    "啊": ("a", "(particle of surprise or emphasis)"), "包": ("bāo", "bag; to wrap"),
    "刮": ("guā", "to blow (wind); to scrape"), "花": ("huā", "flower; to spend"),
    "脚": ("jiǎo", "foot"), "米": ("mǐ", "rice; meter"), "双": ("shuāng", "pair; double"),
    "春": ("chūn", "spring"), "秋": ("qiū", "autumn"), "夏": ("xià", "summer"), "冬": ("dōng", "winter"),
    "东": ("dōng", "east"), "西": ("xī", "west"), "南": ("nán", "south"), "段": ("duàn", "section; period"),
    "班": ("bān", "class; shift"), "草": ("cǎo", "grass"), "楼": ("lóu", "building; floor"),
    "马": ("mǎ", "horse"), "黄": ("huáng", "yellow"), "蓝": ("lán", "blue"), "刷": ("shuā", "to brush"),
    "碗": ("wǎn", "bowl"), "鞋": ("xié", "shoe"), "伞": ("sǎn", "umbrella"), "腿": ("tuǐ", "leg"),
    "糖": ("táng", "sugar; candy"), "祝": ("zhù", "to wish"), "借": ("jiè", "to borrow; to lend"),
    "裤子": ("kùzi", "trousers"), "复习": ("fùxí", "to review"), "刚才": ("gāngcái", "just now"),
    "了解": ("liǎojiě", "to understand; to know about"), "拿": ("ná", "to hold; to take"),
    "白": ("bái", "white"), "百": ("bǎi", "hundred"), "船": ("chuán", "boat"), "高": ("gāo", "tall; high"),
    "黑": ("hēi", "black; dark"), "红": ("hóng", "red"), "药": ("yào", "medicine"), "雪": ("xuě", "snow"),
    "鱼": ("yú", "fish"), "吃": ("chī", "to eat"), "冷": ("lěng", "cold"), "能": ("néng", "can; be able to"),
    "三": ("sān", "three"), "是": ("shì", "to be"), "书": ("shū", "book"), "水": ("shuǐ", "water"),
    "你": ("nǐ", "you"), "老": ("lǎo", "old"), "带": ("dài", "to bring; to carry; to take along"), "这": ("zhè", "this"), "去": ("qù", "to go"), "超市": ("chāoshì", "supermarket"), "奶奶": ("nǎinai", "grandma (father's mother)"), "爷爷": ("yéye", "grandpa (father's father)"), "放": ("fàng", "to put; to place; to let go"), "接": ("jiē", "to pick up (someone); to receive"), "条": ("tiáo", "(measure word for long thin things)"), "位": ("wèi", "(polite measure word for people)"), "层": ("céng", "floor; layer"), "辆": ("liàng", "(measure word for vehicles)"), "西": ("xī", "west"), "越": ("yuè", "the more… (越…越…)"),
}

SKIP_MEANING = re.compile(r"^(CL:|variant of|old variant|surname|abbr\.|see |also written|used in|\(dialect\)|\(old\))", re.I)


def join_pinyin(p: str) -> str:
    """'ā yí' -> 'āyí', 'Tiān ān mén' style apostrophes for vowel-initial syllables."""
    sylls = p.split()
    out = sylls[0] if sylls else ""
    for s in sylls[1:]:
        if s[:1].lower() in "aāáǎàeēéěèoōóǒò":
            out += "'"
        out += s
    return out


def useful(meanings: list[str]) -> list[str]:
    return [m for m in meanings if not SKIP_MEANING.match(m.strip())]


def choose_form(forms: list[dict]) -> dict:
    """Prefer a lowercase (non-surname) reading with real meanings."""
    for f in forms:
        p = f["transcriptions"]["pinyin"]
        if p[:1].islower() and useful(f["meanings"]):
            return f
    return forms[0]


def english(meanings: list[str]) -> str:
    keep = []
    for m in meanings:
        m = re.sub(r"\s*\(?CL:[^)]*\)?", "", m).strip()
        if not m or SKIP_MEANING.match(m):
            continue
        if m not in keep:
            keep.append(m)
        if len(keep) == 3 or len("; ".join(keep)) > 40:
            break
    text = "; ".join(keep[:3]) or meanings[0]
    return text if len(text) <= 60 else text[:57].rsplit(" ", 1)[0] + "…"


def main():
    existing = json.loads(OUT.read_text()) if OUT.exists() else []
    by_hanzi = {w["hanzi"]: w for w in existing}
    used_nums: dict[str, int] = {}
    for w in existing:
        prefix, num = w["id"].split("-")
        used_nums[prefix] = max(used_nums.get(prefix, 0), int(num))

    out = []
    seen = set()
    for level in (1, 2, 3):
        for entry in json.loads((SRC / f"old{level}.json").read_text()):
            h = entry["simplified"]
            if h in seen:
                continue
            seen.add(h)
            old = by_hanzi.get(h)
            if old and old.get("example"):
                # Hand-written entry with an example sentence: keep as is.
                w = dict(old)
                w["level"] = level
            else:
                if old:
                    word_id = old["id"]
                else:
                    n = used_nums.get(str(level), 0) + 1
                    used_nums[str(level)] = n
                    word_id = f"{level}-{n:03d}"
                form = choose_form(entry["forms"])
                w = {
                    "id": word_id,
                    "hanzi": h,
                    "pinyin": join_pinyin(form["transcriptions"]["pinyin"]),
                    "english": english(form["meanings"]),
                    "level": level,
                }
                if h in OVERRIDES:
                    w["pinyin"], w["english"] = OVERRIDES[h]
            w.pop("emoji", None)
            if h in EMOJI:
                w["emoji"] = EMOJI[h]
            if entry.get("radical"):
                w["radical"] = entry["radical"]
            out.append(w)

    # Keep any earlier words that are not in the official lists (e.g. 饭店) so progress isn't lost.
    for w in existing:
        if w["hanzi"] not in seen:
            w = dict(w)
            w.pop("emoji", None)
            if w["hanzi"] in EMOJI:
                w["emoji"] = EMOJI[w["hanzi"]]
            out.append(w)

    ids = [w["id"] for w in out]
    assert len(ids) == len(set(ids)), "duplicate IDs"
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n")
    # Picture -> Wikipedia article whose lead photo the app shows (loaded at runtime, cached).
    from photo_titles import PHOTO_TITLES
    (ROOT / "HSKPrep" / "Photos.json").write_text(json.dumps(PHOTO_TITLES, ensure_ascii=False, indent=1, sort_keys=True) + "\n")
    print(f"{len(PHOTO_TITLES)} pictures have a photo")
    for lvl in (1, 2, 3):
        words = [w for w in out if w["level"] == lvl]
        print(f"HSK {lvl}: {len(words)} words, {sum('emoji' in w for w in words)} with pictures")


if __name__ == "__main__":
    main()
