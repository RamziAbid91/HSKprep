#!/usr/bin/env python3
"""Builds HSKPrep/ExamContent.json — the exam-style listening & reading bank.

All items are ORIGINAL practice material written in the style of the HSK 2.0
papers (picture items, ★ true/false statements, dialogues with a question,
longer passages, question→reply matching, fill-in-the-blank). They are not
official exam questions. Pinyin is generated with pypinyin (pip install pypinyin).

Line format: "M:…" = man, "F:…" = woman, no prefix = narrator.
Add new items below, then run:  python3 tools/build_content.py
"""
import json
from pathlib import Path

from pypinyin import Style, pinyin

OUT = Path(__file__).resolve().parent.parent / "HSKPrep" / "ExamContent.json"
PUNCT = set("，。？！、：；“”\"…（）")


def py(text: str) -> str:
    """Tone-marked pinyin, syllables separated by spaces, punctuation kept."""
    parts = []
    for ch, syl in zip(text, pinyin(text, style=Style.TONE, errors=lambda x: list(x))):
        s = syl[0]
        if ch in PUNCT:
            mapped = {"，": ",", "。": ".", "？": "?", "！": "!", "、": ",", "：": ":", "；": ";"}.get(ch, ch)
            if parts:
                parts[-1] += mapped
            continue
        parts.append(s)
    return " ".join(parts)


def lines(raw: list[str]) -> list[dict]:
    out = []
    for l in raw:
        speaker, text = ("N", l)
        if l[:2] in ("M:", "F:"):
            speaker, text = l[0], l[2:]
        out.append({"speaker": speaker, "text": text, "pinyin": py(text)})
    return out


listening: list[dict] = []
reading: list[dict] = []
counter: dict[str, int] = {}


def next_id(prefix: str) -> str:
    counter[prefix] = counter.get(prefix, 0) + 1
    return f"{prefix}-{counter[prefix]:02d}"


# ── Listening builders ────────────────────────────────────────────────

def picture(level, raw, emoji, english):
    """Hear a sentence or short dialogue, pick the matching picture."""
    listening.append({"id": next_id(f"L{level}-pic"), "level": level, "kind": "picture",
                      "lines": lines(raw), "english": english, "picture": emoji})


def statement(level, raw, star, is_true, english, star_english):
    """Hear a passage, decide if the ★ statement is true."""
    listening.append({"id": next_id(f"L{level}-tf"), "level": level, "kind": "statement",
                      "lines": lines(raw), "english": english,
                      "statement": star, "statementPinyin": py(star), "statementEnglish": star_english,
                      "isTrue": is_true})


def dialogue(level, raw, question, options, answer, english, q_english, kind="dialogue"):
    """Hear a dialogue (or a long passage), answer a question (3 options)."""
    listening.append({"id": next_id(f"L{level}-{'dlg' if kind == 'dialogue' else 'psg'}"), "level": level,
                      "kind": kind, "lines": lines(raw), "english": english,
                      "question": question, "questionPinyin": py(question), "questionEnglish": q_english,
                      "options": options, "answer": answer})


def passage(level, raw, question, options, answer, english, q_english):
    dialogue(level, raw, question, options, answer, english, q_english, kind="passage")


# ── Reading builders ──────────────────────────────────────────────────

def reply(level, question, answer, english):
    """Choose the best reply to a question (other replies of the level are distractors)."""
    reading.append({"id": next_id(f"R{level}-qa"), "level": level, "kind": "reply",
                    "text": question, "pinyin": py(question), "reply": answer, "replyPinyin": py(answer),
                    "english": english})


def cloze(level, sentence, options, answer, english):
    """Fill the blank (＿＿) with the right word."""
    reading.append({"id": next_id(f"R{level}-cz"), "level": level, "kind": "cloze",
                    "text": sentence, "pinyin": py(sentence.replace("＿＿", options[answer])),
                    "options": options, "answer": answer, "english": english})


def read_tf(level, text, star, is_true, english, star_english):
    reading.append({"id": next_id(f"R{level}-tf"), "level": level, "kind": "passageTrueFalse",
                    "text": text, "pinyin": py(text), "english": english,
                    "statement": star, "statementPinyin": py(star), "statementEnglish": star_english,
                    "isTrue": is_true})


def read_q(level, text, question, options, answer, english, q_english):
    reading.append({"id": next_id(f"R{level}-pq"), "level": level, "kind": "passageQuestion",
                    "text": text, "pinyin": py(text), "english": english,
                    "question": question, "questionPinyin": py(question), "questionEnglish": q_english,
                    "options": options, "answer": answer})


# ══════════════════════════════════════════════════════════════════════
# HSK 1
# ══════════════════════════════════════════════════════════════════════
picture(1, ["我喜欢喝茶。"], "🍵", "I like drinking tea.")
picture(1, ["她家有一个小猫。"], "🐈", "Her family has a little cat.")
picture(1, ["他是医生。"], "🧑‍⚕️", "He is a doctor.")
picture(1, ["今天下雨了。"], "🌧️", "It's raining today.")
picture(1, ["我们坐出租车去吧。"], "🚕", "Let's take a taxi.")
picture(1, ["爸爸在看电视。"], "📺", "Dad is watching TV.")
picture(1, ["这是我的电脑。"], "💻", "This is my computer.")
picture(1, ["我想吃苹果。"], "🍎", "I want to eat an apple.")
picture(1, ["我女儿在睡觉。"], "😴", "My daughter is sleeping.")
picture(1, ["M:你好！", "F:你好，很高兴认识你。"], "🤝", "Hello! — Hello, nice to meet you.")
picture(1, ["M:喂，你在哪儿？", "F:我在医院。"], "🏥", "Hello, where are you? — I'm at the hospital.")
picture(1, ["F:你几点去火车站？", "M:下午三点。"], "🚉", "What time are you going to the train station? — 3 pm.")
picture(1, ["M:你买什么了？", "F:我买了一些衣服。"], "👕", "What did you buy? — I bought some clothes.")
picture(1, ["F:桌子上有几本书？", "M:三本。"], "📚", "How many books are on the table? — Three.")
picture(1, ["M:你女儿多大了？", "F:她七岁了。"], "👧", "How old is your daughter? — She's seven.")
picture(1, ["F:你会做中国菜吗？", "M:会，我做的米饭很好吃。"], "🍚", "Can you cook Chinese food? — Yes, my rice is delicious.")
picture(1, ["M:你明天怎么去北京？", "F:坐飞机去。"], "✈️", "How are you getting to Beijing tomorrow? — By plane.")
picture(1, ["F:这是谁的狗？", "M:是我朋友的。"], "🐕", "Whose dog is this? — My friend's.")

dialogue(1, ["F:你下午去哪儿？", "M:我去商店买水果。"], "他下午去哪儿？",
         ["商店", "医院", "学校"], 0, "Where are you going this afternoon? — To the shop to buy fruit.", "Where is he going this afternoon?")
dialogue(1, ["M:现在几点？", "F:十点十分。"], "现在几点？",
         ["十点", "十点十分", "十一点"], 1, "What time is it? — Ten past ten.", "What time is it now?")
dialogue(1, ["F:你想喝什么？", "M:我想喝水，谢谢。"], "他想喝什么？",
         ["茶", "水", "牛奶"], 1, "What would you like to drink? — Water, thanks.", "What does he want to drink?")
dialogue(1, ["M:那个人是谁？", "F:是我的汉语老师。"], "那个人是谁？",
         ["老师", "医生", "同学"], 0, "Who is that person? — My Chinese teacher.", "Who is that person?")
dialogue(1, ["F:你的书在哪儿？", "M:在桌子上。"], "书在哪儿？",
         ["椅子下面", "桌子上", "电脑后面"], 1, "Where is your book? — On the table.", "Where is the book?")
dialogue(1, ["M:明天天气怎么样？", "F:明天很冷。"], "明天天气怎么样？",
         ["很热", "下雨", "很冷"], 2, "What's the weather like tomorrow? — It'll be cold.", "What will the weather be like tomorrow?")
dialogue(1, ["F:你什么时候去北京？", "M:星期五。"], "他什么时候去北京？",
         ["星期三", "星期五", "星期天"], 1, "When are you going to Beijing? — Friday.", "When is he going to Beijing?")
dialogue(1, ["M:你家有几个人？", "F:我家有四个人。"], "她家有几个人？",
         ["三个", "四个", "五个"], 1, "How many people are in your family? — Four.", "How many people are in her family?")
dialogue(1, ["F:这些苹果多少钱？", "M:十五块。"], "苹果多少钱？",
         ["五块", "十块", "十五块"], 2, "How much are these apples? — 15 kuai.", "How much are the apples?")
dialogue(1, ["M:你认识王小姐吗？", "F:认识，她是我同学。"], "王小姐是她的什么人？",
         ["同学", "女儿", "老师"], 0, "Do you know Miss Wang? — Yes, she's my classmate.", "Who is Miss Wang to her?")
dialogue(1, ["F:你会开车吗？", "M:不会，我是坐出租车来的。"], "他怎么来的？",
         ["开车", "坐出租车", "坐飞机"], 1, "Can you drive? — No, I came by taxi.", "How did he come?")
dialogue(1, ["M:你中午吃什么？", "F:我想去饭馆吃米饭和菜。"], "她中午想吃什么？",
         ["米饭和菜", "水果", "苹果"], 0, "What are you having for lunch? — I want rice and dishes at a restaurant.", "What does she want for lunch?")

reply(1, "你叫什么名字？", "我叫李明。", "What's your name? — I'm Li Ming.")
reply(1, "你今年多大？", "我二十岁。", "How old are you this year? — I'm twenty.")
reply(1, "你是哪国人？", "我是中国人。", "Which country are you from? — I'm Chinese.")
reply(1, "你想喝点儿什么？", "来一杯茶吧。", "What would you like to drink? — A cup of tea, please.")
reply(1, "你住在哪儿？", "我住在学校后面。", "Where do you live? — Behind the school.")
reply(1, "对不起！", "没关系。", "Sorry! — That's OK.")
reply(1, "谢谢你！", "不客气。", "Thank you! — You're welcome.")
reply(1, "你什么时候回家？", "明天上午。", "When are you going home? — Tomorrow morning.")
reply(1, "这个杯子多少钱？", "二十块。", "How much is this cup? — 20 kuai.")
reply(1, "你喜欢看电影吗？", "很喜欢。", "Do you like watching movies? — Very much.")
reply(1, "喂，你在做什么？", "我在学习汉语。", "Hello, what are you doing? — I'm studying Chinese.")
reply(1, "你怎么去医院？", "坐出租车去。", "How are you getting to the hospital? — By taxi.")

cloze(1, "我很喜欢我的汉语＿＿。", ["老师", "米饭", "冷", "开"], 0, "I really like my Chinese teacher.")
cloze(1, "你叫什么＿＿？", ["朋友", "名字", "工作", "东西"], 1, "What's your name?")
cloze(1, "他在医院＿＿，他是医生。", ["睡觉", "喝", "工作", "漂亮"], 2, "He works at a hospital; he's a doctor.")
cloze(1, "今天太＿＿了，我不想出去。", ["冷", "少", "开", "读"], 0, "It's too cold today, I don't want to go out.")
cloze(1, "这是我的好＿＿。", ["桌子", "天气", "朋友", "水"], 2, "This is my good friend.")
cloze(1, "我＿＿去中国学习汉语。", ["叫", "想", "是", "有"], 1, "I want to go to China to study Chinese.")
cloze(1, "她的衣服很＿＿。", ["学习", "喜欢", "点", "漂亮"], 3, "Her clothes are very pretty.")
cloze(1, "我们＿＿飞机去北京。", ["坐", "做", "看", "听"], 0, "We're flying to Beijing.")
cloze(1, "桌子＿＿有一本书。", ["大", "上", "个", "多"], 1, "There's a book on the table.")
cloze(1, "你＿＿说汉语吗？", ["去", "在", "会", "和"], 2, "Can you speak Chinese?")
cloze(1, "现在下午三＿＿。", ["岁", "点", "块", "个"], 1, "It's 3 pm now.")
cloze(1, "我们一起去商店＿＿东西吧。", ["读", "写", "听", "买"], 3, "Let's go shopping together.")

# ══════════════════════════════════════════════════════════════════════
# HSK 2
# ══════════════════════════════════════════════════════════════════════
picture(2, ["他每天早上都去跑步。"], "🏃", "He goes running every morning.")
picture(2, ["我今天生病了，不想吃东西。"], "🤒", "I'm sick today and don't want to eat.")
picture(2, ["她在唱歌，唱得非常好。"], "🎤", "She's singing, and she sings really well.")
picture(2, ["孩子们在外面踢足球。"], "⚽", "The children are playing football outside.")
picture(2, ["外面下雪了，真漂亮！"], "❄️", "It's snowing outside — beautiful!")
picture(2, ["M:你的手机呢？", "F:在房间的桌子上。"], "📱", "Where's your phone? — On the table in the room.")
picture(2, ["F:我们坐公共汽车去吧。", "M:好，车站就在前面。"], "🚌", "Let's take the bus. — OK, the stop is just ahead.")
picture(2, ["M:服务员，再来两个鸡蛋。", "F:好的，请等一下。"], "🥚", "Waiter, two more eggs please. — Sure, one moment.")
picture(2, ["F:生日快乐！这是送给你的。", "M:谢谢！"], "🎂", "Happy birthday! This is for you. — Thanks!")
picture(2, ["M:你每天怎么去公司？", "F:我骑自行车去。"], "🚲", "How do you get to the office? — I ride a bike.")
picture(2, ["F:你喜欢吃西瓜吗？", "M:喜欢，夏天吃西瓜最好了。"], "🍉", "Do you like watermelon? — Yes, it's best in summer.")
picture(2, ["M:你在看什么？", "F:今天的报纸。"], "📰", "What are you reading? — Today's newspaper.")
picture(2, ["F:这些药一天吃三次。", "M:好的，谢谢医生。"], "💊", "Take this medicine three times a day. — OK, thank you, doctor.")
picture(2, ["M:你会游泳吗？", "F:会，我每个星期都去游泳。"], "🏊", "Can you swim? — Yes, I swim every week.")

statement(2, ["我妹妹非常喜欢跳舞，她每个星期六都去学跳舞。"], "妹妹星期六去学跳舞。", True,
          "My younger sister loves dancing; she has dance class every Saturday.", "The sister learns dancing on Saturdays.")
statement(2, ["今天天气很好，是晴天，我们下午一起去公园跑步吧。"], "今天下雨了。", False,
          "The weather's great today, it's sunny — let's go running in the park this afternoon.", "It rained today.")
statement(2, ["我家离公司很近，走路十分钟就到了，所以我每天走路去上班。"], "他每天坐公共汽车上班。", False,
          "My home is close to the office — ten minutes on foot — so I walk to work every day.", "He takes the bus to work every day.")
statement(2, ["这件衣服颜色很好看，但是太贵了，我不想买。"], "他觉得那件衣服很便宜。", False,
          "This piece of clothing is a nice colour, but it's too expensive; I don't want to buy it.", "He thinks the clothing is cheap.")
statement(2, ["我丈夫是医生，他工作非常忙，晚上常常十点以后才回家。"], "她丈夫工作很忙。", True,
          "My husband is a doctor. He's very busy and often gets home after ten at night.", "Her husband is very busy at work.")
statement(2, ["我已经准备好了，考试是明天上午九点，在三号教室。"], "考试在下午。", False,
          "I'm ready. The exam is at 9 tomorrow morning, in classroom 3.", "The exam is in the afternoon.")
statement(2, ["哥哥比我大三岁，他今年二十五岁了。"], "说话人今年二十二岁。", True,
          "My older brother is three years older than me; he's 25 this year.", "The speaker is 22 this year.")
statement(2, ["欢迎大家来中国旅游！我们今天先去吃北京菜，明天去看长城。"], "他们明天去看长城。", True,
          "Welcome to China, everyone! Today we'll eat Beijing food, and tomorrow we'll see the Great Wall.", "They'll see the Great Wall tomorrow.")
statement(2, ["我每天晚上十一点睡觉，早上六点半起床，然后去跑步。"], "他早上七点起床。", False,
          "I go to bed at 11 every night, get up at 6:30 and then go running.", "He gets up at 7 in the morning.")

dialogue(2, ["F:你怎么还没起床？已经八点了！", "M:我昨天晚上看书看到很晚，太累了。"], "男的为什么还没起床？",
         ["他生病了", "他很累", "他不上班"], 1, "Why aren't you up yet? It's already 8! — I read until late last night, I'm exhausted.", "Why isn't the man up yet?")
dialogue(2, ["M:这个西瓜多少钱一公斤？", "F:三块五。你要几公斤？", "M:我要两公斤。"], "男的要买多少西瓜？",
         ["一公斤", "两公斤", "三公斤"], 1, "How much per kilo is this watermelon? — 3.50. How many kilos? — Two.", "How much watermelon does the man buy?")
dialogue(2, ["F:你找什么呢？", "M:我的手表，我记得放在桌子上了。"], "男的在找什么？",
         ["手机", "手表", "报纸"], 1, "What are you looking for? — My watch; I think I put it on the table.", "What is the man looking for?")
dialogue(2, ["M:喂，你到机场了吗？", "F:还没有，路上车太多了，我可能晚半个小时。"], "女的现在在哪儿？",
         ["机场", "路上", "家里"], 1, "Hello, are you at the airport? — Not yet, the traffic's bad; I may be half an hour late.", "Where is the woman now?")
dialogue(2, ["F:你会游泳吗？", "M:会，但是游得不好。我哥哥游得比我好。"], "谁游泳游得好？",
         ["男的", "男的哥哥", "女的"], 1, "Can you swim? — Yes, but not well. My brother swims better than me.", "Who swims well?")
dialogue(2, ["M:医生，我孩子的病怎么样了？", "F:没什么问题，吃点儿药，休息两天就好了。"], "孩子要做什么？",
         ["吃药休息", "去医院", "去学校"], 0, "Doctor, how is my child? — Nothing serious; some medicine and two days' rest.", "What does the child need to do?")
dialogue(2, ["F:你们公司离这儿远吗？", "M:不远，坐公共汽车二十分钟就到了。"], "男的怎么去公司？",
         ["开车", "坐公共汽车", "走路"], 1, "Is your company far from here? — No, twenty minutes by bus.", "How does the man get to his company?")
dialogue(2, ["M:你的新同学怎么样？", "F:很好，她很爱笑，大家都喜欢她。"], "女的觉得新同学怎么样？",
         ["很好", "不好", "很忙"], 0, "How's your new classmate? — Great, she smiles a lot and everyone likes her.", "What does the woman think of her new classmate?")
dialogue(2, ["F:我们几号去旅游？", "M:十月一号，坐飞机去。票我已经买好了。"], "他们什么时候去旅游？",
         ["十月一号", "十号", "一月十号"], 0, "What date are we going on our trip? — October 1st, by plane. I've already bought the tickets.", "When are they travelling?")
dialogue(2, ["M:你今天穿得真漂亮！", "F:谢谢，今天是我的生日，晚上要和朋友们去吃饭。"], "女的今天晚上做什么？",
         ["上班", "和朋友吃饭", "去考试"], 1, "You look great today! — Thanks, it's my birthday; I'm having dinner with friends tonight.", "What is the woman doing tonight?")
dialogue(2, ["F:这个题你懂了吗？", "M:还不太懂，你能再给我介绍一下吗？"], "男的是什么意思？",
         ["他懂了", "他还不懂", "他不想学"], 1, "Do you understand this question? — Not quite, can you explain it again?", "What does the man mean?")
dialogue(2, ["M:外面阴天了，可能要下雨，你带伞吧。", "F:好的，谢谢。"], "男的让女的做什么？",
         ["带伞", "穿衣服", "回家"], 0, "It's cloudy, it might rain — take an umbrella. — OK, thanks.", "What does the man tell the woman to do?")

reply(2, "你每天几点起床？", "六点半，我要早点儿去上班。", "What time do you get up? — 6:30, I need to get to work early.")
reply(2, "你在哪儿工作？", "我在一家公司工作。", "Where do you work? — At a company.")
reply(2, "你身体怎么样？", "很好，我每天都去跑步。", "How's your health? — Great, I go running every day.")
reply(2, "这件衣服怎么样？", "颜色很好看，但是有点儿贵。", "What do you think of this piece of clothing? — Nice colour, but a bit expensive.")
reply(2, "你怎么还在看电视？", "我已经准备好明天的考试了。", "Why are you still watching TV? — I'm already ready for tomorrow's exam.")
reply(2, "你去过中国吗？", "去过两次，都是去旅游。", "Have you been to China? — Twice, both times as a tourist.")
reply(2, "我们什么时候考试？", "下个星期三。", "When is our exam? — Next Wednesday.")
reply(2, "你为什么不吃鱼？", "因为我昨天已经吃过了。", "Why aren't you eating the fish? — Because I already had some yesterday.")
reply(2, "你认识那个穿红衣服的女孩子吗？", "认识，她是我妹妹。", "Do you know the girl in red? — Yes, she's my younger sister.")
reply(2, "你觉得这个电影怎么样？", "非常好看，我想再看一次。", "What did you think of the movie? — Excellent, I want to see it again.")

cloze(2, "我＿＿吃过饭了，你们吃吧。", ["已经", "正在", "因为", "比"], 0, "I've already eaten, go ahead.")
cloze(2, "他＿＿我高一点儿。", ["从", "比", "离", "给"], 1, "He's a little taller than me.")
cloze(2, "学校＿＿我家不太远。", ["从", "在", "离", "向"], 2, "The school isn't far from my home.")
cloze(2, "＿＿下雨了，所以我们没去公园。", ["因为", "但是", "虽然", "还是"], 0, "Because it rained, we didn't go to the park.")
cloze(2, "他每天＿＿六点起床。", ["中午", "早上", "去年", "小时"], 1, "He gets up at six every morning.")
cloze(2, "请＿＿我一杯咖啡。", ["送", "让", "对", "给"], 3, "Please give me a cup of coffee.")
cloze(2, "这个问题太难了，我不＿＿。", ["找", "送", "懂", "笑"], 2, "This question is too hard, I don't understand it.")
cloze(2, "她正在＿＿明天的考试。", ["准备", "介绍", "希望", "告诉"], 0, "She's preparing for tomorrow's exam.")
cloze(2, "你看，那＿＿衣服真漂亮。", ["张", "件", "本", "个"], 1, "Look, that piece of clothing is really pretty.")
cloze(2, "我昨天＿＿了，没去上班。", ["生病", "唱歌", "旅游", "欢迎"], 0, "I was sick yesterday and didn't go to work.")
cloze(2, "我＿＿你明天能来我家玩儿。", ["告诉", "介绍", "希望", "欢迎"], 2, "I hope you can come over to my place tomorrow.")

read_tf(2, "我和妻子都很喜欢运动。每个星期天上午，我们都去公园跑步，下午在家休息。", "他们星期天下午去跑步。", False,
        "My wife and I both love sport. Every Sunday morning we run in the park, and rest at home in the afternoon.", "They go running on Sunday afternoons.")
read_tf(2, "这家商店的东西又好又便宜，所以每天来买东西的人都非常多。", "这家商店的东西很贵。", False,
        "This shop's things are good and cheap, so lots of people come every day.", "This shop's things are expensive.")
read_tf(2, "我弟弟今年上大学了，他学习很努力，每天晚上都在教室看书。", "弟弟学习很努力。", True,
        "My younger brother started university this year. He studies hard and reads in the classroom every evening.", "The younger brother studies hard.")

# ══════════════════════════════════════════════════════════════════════
# HSK 3
# ══════════════════════════════════════════════════════════════════════
picture(3, ["M:你看，这个熊猫多可爱啊！", "F:是啊，它正在吃东西呢。"], "🐼", "Look how cute this panda is! — Yes, it's eating.")
picture(3, ["F:你先把行李箱放在这儿，我去拿护照。", "M:好的，我在这儿等你。"], "🧳", "Put the suitcase here first, I'll get the passports. — OK, I'll wait here.")
picture(3, ["M:我感冒了，头有点儿疼。", "F:你快去医院看看吧。"], "🤧", "I've caught a cold and have a bit of a headache. — Go and see a doctor.")
picture(3, ["F:周末我们去爬山吧？", "M:好啊，山上的空气特别新鲜。"], "🧗", "Shall we go hiking this weekend? — Sure, the mountain air is so fresh.")
picture(3, ["M:你的眼镜呢？", "F:我刚才还看见了，怎么找不到了？"], "👓", "Where are your glasses? — I saw them a moment ago — why can't I find them?")
picture(3, ["F:下班后我要去超市买点儿面包和牛奶。", "M:帮我带一瓶果汁吧。"], "🛒", "After work I'm going to the supermarket for bread and milk. — Get me a bottle of juice.")
picture(3, ["M:快点儿，电梯来了！", "F:等等我！"], "🛗", "Hurry, the lift is here! — Wait for me!")
picture(3, ["F:生日快乐！我给你做了一个蛋糕。", "M:太谢谢你了！"], "🍰", "Happy birthday! I made you a cake. — Thank you so much!")
picture(3, ["M:外面刮风了，好像要下雨。", "F:别忘了带伞。"], "☂️", "It's windy outside, looks like rain. — Don't forget your umbrella.")
picture(3, ["F:你经常骑自行车上班吗？", "M:对，又方便又能锻炼身体。"], "🚴", "Do you often cycle to work? — Yes, it's convenient and good exercise.")
picture(3, ["M:这双鞋有点儿小，有大一点儿的吗？", "F:有，您等一下。"], "👟", "These shoes are a bit small, do you have a bigger size? — Yes, one moment.")
picture(3, ["F:你在画什么？", "M:我在画我们家的小猫。"], "🎨", "What are you drawing? — Our kitten.")

statement(3, ["我以前觉得学习汉语很难，但是来中国一年以后，我发现其实没有那么难，现在我已经能用汉语和邻居说话了。"],
          "他现在觉得汉语比以前容易。", True,
          "I used to think Chinese was hard, but after a year in China I found it isn't that hard; now I can talk with my neighbours in Chinese.",
          "He now finds Chinese easier than before.")
statement(3, ["这家饭馆的菜虽然有点儿贵，但是非常新鲜，而且服务员都很热情，所以每到周末，这里的客人都特别多。"],
          "这家饭馆周末客人很少。", False,
          "This restaurant is a bit expensive, but the food is very fresh and the staff are friendly, so it's packed every weekend.",
          "This restaurant has few customers at weekends.")
statement(3, ["我爷爷今年八十岁了，身体还很健康。他每天早上都去公园锻炼一个小时，下午在家看看报纸，画画儿。"],
          "爷爷每天下午去公园。", False,
          "My grandfather is 80 and still healthy. He exercises in the park for an hour every morning, and reads the paper and paints at home in the afternoon.",
          "Grandpa goes to the park every afternoon.")
statement(3, ["小王，经理让你明天上午九点到他办公室去一下，他想了解一下你最近的工作。"],
          "经理明天上午要见小王。", True,
          "Xiao Wang, the manager wants you in his office at 9 tomorrow morning; he wants to hear about your recent work.",
          "The manager will see Xiao Wang tomorrow morning.")
statement(3, ["坐地铁去机场又快又便宜，一般只要四十分钟。如果坐出租车，路上车多的时候，可能需要一个多小时。"],
          "坐地铁去机场比坐出租车快。", True,
          "The subway to the airport is fast and cheap, usually only 40 minutes. A taxi can take over an hour when traffic is heavy.",
          "The subway to the airport is faster than a taxi.")
statement(3, ["我的房间在三层，房间外面就是一个小花园。春天的时候，花园里开满了花，非常漂亮。"],
          "他的房间在一层。", False,
          "My room is on the third floor, right above a little garden. In spring the garden is full of flowers — beautiful.",
          "His room is on the first floor.")
statement(3, ["我妹妹特别喜欢小动物，她家里有一只小猫和两只小鸟。每天放学回家，她第一件事就是给它们吃东西。"],
          "妹妹有两只猫。", False,
          "My younger sister loves small animals; she has a kitten and two little birds. The first thing she does after school is feed them.",
          "The younger sister has two cats.")
statement(3, ["这次考试我的成绩不太好，我决定以后每天晚上都复习一个小时，下次一定要考好。"],
          "他对这次考试的成绩很满意。", False,
          "My results in this exam weren't good. I've decided to review for an hour every evening so I do well next time.",
          "He's satisfied with his exam results.")

dialogue(3, ["F:你怎么又迟到了？", "M:对不起，路上车太多了，公共汽车半天都不来。", "F:下次早点儿出门吧。"], "男的为什么迟到了？",
         ["起床晚了", "公共汽车来得慢", "忘了时间"], 1,
         "Why are you late again? — Sorry, the traffic was bad and the bus took ages. — Leave earlier next time.", "Why was the man late?")
dialogue(3, ["M:你周末打算做什么？", "F:我想去图书馆借几本书，然后去看看奶奶。", "M:你奶奶住得远吗？", "F:不远，坐地铁两站就到了。"],
         "女的周末不会去哪儿？", ["图书馆", "奶奶家", "超市"], 2,
         "What are your plans for the weekend? — The library to borrow books, then visit my grandma. — Does she live far? — No, two subway stops.",
         "Where will the woman NOT go this weekend?")
dialogue(3, ["M:这条裙子你穿着真好看，在哪儿买的？", "F:在学校附近的商店，现在买一送一，特别便宜。"], "那个商店在哪儿？",
         ["学校附近", "公司旁边", "银行对面"], 0,
         "That dress looks great on you, where did you buy it? — At a shop near the school; it's buy-one-get-one-free right now.", "Where is the shop?")
dialogue(3, ["M:服务员，菜单上的这个菜是甜的吗？", "F:有一点儿甜，很多客人都喜欢。", "M:那就来一个吧，再要一碗米饭。"], "他们最可能在哪儿？",
         ["饭馆", "超市", "银行"], 0,
         "Waiter, is this dish on the menu sweet? — A little; lots of customers like it. — Then I'll have one, and a bowl of rice.", "Where are they most likely to be?")
dialogue(3, ["F:你的汉语说得越来越好了！", "M:谢谢，我每天都跟中国同事练习说话。"], "男的怎么练习汉语？",
         ["看电视", "跟同事说话", "上网"], 1,
         "Your Chinese is getting better and better! — Thanks, I practise speaking with my Chinese colleagues every day.", "How does the man practise Chinese?")
dialogue(3, ["M:空调好像坏了，房间里太热了。", "F:我已经给经理打电话了，他说一会儿就找人来看看。"], "关于空调，可以知道什么？",
         ["已经好了", "坏了", "太冷了"], 1,
         "The air conditioning seems broken, it's too hot in here. — I've called the manager; he'll send someone soon.", "What do we learn about the air conditioning?")
dialogue(3, ["F:你决定了吗？去北京还是去上海工作？", "M:还没有。北京的机会多，但是我的家人都在上海。"], "男的为什么还没决定？",
         ["他不想工作", "他的家人在上海", "北京太远"], 1,
         "Have you decided — Beijing or Shanghai? — Not yet. Beijing has more opportunities, but my family is in Shanghai.", "Why hasn't the man decided?")
dialogue(3, ["M:我的护照找不到了，下午的飞机怎么办？", "F:别着急，你再好好想想，是不是放在行李箱里了？"], "男的为什么着急？",
         ["护照找不到了", "飞机票太贵", "行李箱坏了"], 0,
         "I can't find my passport — what about this afternoon's flight? — Don't panic, think again: is it in your suitcase?", "Why is the man anxious?")
dialogue(3, ["F:你女儿上几年级了？", "M:三年级了，她数学特别好，就是不太喜欢写字。"], "男的的女儿不喜欢做什么？",
         ["学数学", "写字", "上学"], 1,
         "What grade is your daughter in? — Third grade. She's great at maths, but doesn't like writing characters.", "What doesn't his daughter like doing?")
dialogue(3, ["M:今天的会议什么时候结束？", "F:大概五点半。你有事吗？", "M:我六点要去学校接儿子。"], "男的六点要做什么？",
         ["开会", "接儿子", "去银行"], 1,
         "When does today's meeting end? — Around 5:30. Do you have plans? — I need to pick up my son from school at 6.", "What does the man need to do at 6?")

passage(3, ["很多人觉得早上锻炼身体最好，其实不一定。早上刚起床的时候，身体还没有完全准备好，如果马上去跑步，可能对身体不好。一般来说，下午四点到六点是锻炼的好时间。"],
        "这段话主要想告诉我们什么？", ["早上必须跑步", "下午锻炼可能更好", "锻炼对身体不好"], 1,
        "Many people think morning is the best time to exercise, but not necessarily. Right after waking the body isn't ready, so running immediately may not be good. Generally 4–6 pm is a good time to exercise.",
        "What is this passage mainly telling us?")
passage(3, ["我叫李明，是一名大学生。我的爱好是照相，每到周末，我都会带着照相机去公园或者河边。我最喜欢照小鸟和花草。去年，我的一张照片还在学校的比赛中得了第一名。"],
        "李明的照片怎么了？", ["被他忘在公园了", "在比赛中得了第一名", "卖了很多钱"], 1,
        "My name is Li Ming, I'm a university student. My hobby is photography; every weekend I take my camera to the park or the river. I love photographing birds and plants. Last year one of my photos won first prize in a school competition.",
        "What happened to Li Ming's photo?")
passage(3, ["上个星期，我搬到了新家。新家离公司比较远，以前我走路十分钟就能到，现在要坐四十分钟的地铁。不过新家附近有一个很大的公园，环境特别好，所以我还是很满意。"],
        "说话人觉得新家怎么样？", ["很满意", "太远了，不喜欢", "不太安静"], 0,
        "Last week I moved house. The new place is further from the office — it used to be a ten-minute walk, now it's 40 minutes by subway. But there's a big park nearby and the environment is lovely, so I'm still very happy.",
        "How does the speaker feel about the new home?")
passage(3, ["中国人过春节的时候，一家人一定要在一起吃饭。很多在别的城市工作的年轻人，都会在春节以前回家。所以每年这个时候，火车票和飞机票都特别难买。"],
        "为什么春节以前票很难买？", ["很多人要回家", "票太贵了", "火车太少"], 0,
        "At Spring Festival, Chinese families must eat together. Many young people who work in other cities go home before the festival, so train and plane tickets are very hard to get at this time every year.",
        "Why are tickets hard to buy before Spring Festival?")
passage(3, ["王老师是我们的数学老师。她上课非常认真，讲得也很清楚。下课以后，她总是愿意留在教室里，一个一个地帮我们解决问题。同学们都很喜欢她。"],
        "关于王老师，下面哪个是对的？", ["她教汉语", "她愿意帮助学生", "她上课不认真"], 1,
        "Ms Wang is our maths teacher. She teaches conscientiously and explains clearly. After class she always stays in the classroom to help us with problems one by one. Everyone likes her.",
        "Which statement about Ms Wang is correct?")
passage(3, ["现在越来越多的人喜欢在网上买东西。上网买东西很方便，不用出门，而且常常比商店便宜。但是有时候，你买到的东西和照片上的不一样，所以买以前最好先看看别人怎么说。"],
        "在网上买东西有什么问题？", ["东西太贵", "东西可能和照片不一样", "必须出门"], 1,
        "More and more people like shopping online. It's convenient — you don't have to go out — and often cheaper than shops. But sometimes what you receive isn't like the photo, so it's best to check what others say before buying.",
        "What problem can online shopping have?")

cloze(3, "我把作业＿＿了，现在可以出去玩儿了吗？", ["完成", "认为", "影响", "发现"], 0, "I've finished my homework — can I go out to play now?")
cloze(3, "外面太冷了，你多穿点儿衣服，别＿＿了。", ["锻炼", "感冒", "检查", "照顾"], 1, "It's cold out, wear more clothes so you don't catch a cold.")
cloze(3, "这个问题有点儿难，我们一起想想＿＿吧。", ["机会", "环境", "办法", "兴趣"], 2, "This problem is a bit hard; let's think of a solution together.")
cloze(3, "他对中国＿＿很感兴趣，所以来北京学习。", ["文化", "成绩", "新闻", "节目"], 0, "He's very interested in Chinese culture, so he came to study in Beijing.")
cloze(3, "你＿＿吧，我一定会照顾好你的猫。", ["着急", "害怕", "生气", "放心"], 3, "Don't worry, I'll definitely look after your cat.")
cloze(3, "我们家＿＿有一个很大的超市，买东西很方便。", ["中间", "附近", "以前", "周末"], 1, "There's a big supermarket near our home; shopping is convenient.")
cloze(3, "这次旅游我们＿＿花了三千块。", ["一定", "一直", "一共", "一样"], 2, "We spent 3,000 kuai in total on this trip.")
cloze(3, "老师说话的＿＿太小了，我听不清楚。", ["声音", "音乐", "故事", "句子"], 0, "The teacher's voice is too quiet, I can't hear clearly.")
cloze(3, "明天的会议很＿＿，你一定要参加。", ["简单", "健康", "重要", "干净"], 2, "Tomorrow's meeting is important; you must attend.")
cloze(3, "我找了一个小时，＿＿找到我的护照了！", ["突然", "终于", "其实", "一般"], 1, "I searched for an hour and finally found my passport!")

read_q(3, "小李最近工作特别忙，每天晚上都要十点以后才下班。他已经两个星期没有去锻炼了，周末也只想在家睡觉。他的女朋友很担心他的身体。",
       "小李的女朋友为什么担心？", ["小李太忙太累", "小李不爱她", "小李生病了"], 0,
       "Xiao Li has been very busy at work lately and only leaves after ten every night. He hasn't exercised for two weeks and only wants to sleep at weekends. His girlfriend is worried about his health.",
       "Why is Xiao Li's girlfriend worried?")
read_q(3, "我住的这个城市冬天不太冷，夏天也不太热，一年四季都很舒服。春天的时候，街道两边的树都绿了；秋天的时候，很多人喜欢去山上照相。",
       "这个城市的天气怎么样？", ["冬天特别冷", "夏天特别热", "一年四季都舒服"], 2,
       "The city I live in isn't too cold in winter or too hot in summer — it's comfortable all year. In spring the trees along the streets turn green; in autumn many people go up the hills to take photos.",
       "What is the weather like in this city?")
read_q(3, "这家超市每个星期三的水果都比别的时候便宜很多，所以每到星期三，超市里的人就特别多。我一般会在下班以后去买一些香蕉和葡萄。",
       "星期三超市的水果怎么样？", ["很新鲜", "比较便宜", "卖完了"], 1,
       "Every Wednesday this supermarket's fruit is much cheaper than usual, so it's very crowded on Wednesdays. I usually go after work to buy bananas and grapes.",
       "What is the supermarket fruit like on Wednesdays?")
read_q(3, "下个月我要去上海参加一个会议，会议一共三天。我打算会议结束以后在上海多留两天，去看看几个老同学。",
       "他打算在上海做什么？", ["只参加会议", "参加会议和看老同学", "去旅游一个月"], 1,
       "Next month I'm going to a three-day conference in Shanghai. I plan to stay two extra days afterwards to see some old classmates.",
       "What does he plan to do in Shanghai?")
read_tf(3, "我的邻居是一位老奶奶，她一个人住。她的儿子和女儿都在国外工作，一年只能回来一次。我有时间的时候，会去她家帮她打扫房间，跟她说说话。",
        "老奶奶和她的儿子住在一起。", False,
        "My neighbour is an elderly lady who lives alone. Her son and daughter work abroad and can only come back once a year. When I have time I help her clean and chat with her.",
        "The old lady lives with her son.")
read_tf(3, "这本书的故事很有意思，讲的是一个熊猫离开家去找妈妈的事情。虽然这是一本给孩子看的书，但是很多大人也很喜欢。",
        "只有孩子喜欢这本书。", False,
        "This book has an interesting story about a panda who leaves home to look for its mother. It's a children's book, but many adults love it too.",
        "Only children like this book.")
read_tf(3, "学习一种语言，最重要的是多听多说。很多人只知道看书、记词语，但是不敢开口说，所以学了很多年还是不会用。",
        "说话人认为学语言要多说。", True,
        "When learning a language, the most important thing is to listen and speak a lot. Many people only read and memorise words but are afraid to speak, so after years they still can't use it.",
        "The speaker thinks you should speak a lot when learning a language.")


def main():
    data = {"listening": listening, "reading": reading}
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n")
    for lvl in (1, 2, 3):
        ln = [i["kind"] for i in listening if i["level"] == lvl]
        rd = [i["kind"] for i in reading if i["level"] == lvl]
        print(f"HSK {lvl}: listening {len(ln)} {sorted(set(ln))} | reading {len(rd)} {sorted(set(rd))}")


if __name__ == "__main__":
    main()
