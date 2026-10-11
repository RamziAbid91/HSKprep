import Foundation

struct GrammarExample: Hashable {
    let chinese: String
    let pinyin: String
    let english: String
}

/// Arrange words into a sentence. `tokens` are in the correct order; the UI shuffles them.
struct SentenceBuilder: Hashable {
    let tokens: [String]
    let english: String
    var answer: String { tokens.joined() }
}

/// Fill in the blank (written as ＿＿ in `sentence`).
struct FillBlank: Hashable {
    let sentence: String
    let options: [String]
    let answer: String
    let english: String
}

struct GrammarPoint: Identifiable, Hashable {
    let id: String
    let level: Int
    let title: String
    let summary: String
    let explanation: String
    let examples: [GrammarExample]
    let commonMistake: String
    let builders: [SentenceBuilder]
    let blanks: [FillBlank]
    var tips: [String] = []     // memory tricks
}

/// Original teaching content (not official exam material).
enum GrammarStore {
    static func points(level: Int) -> [GrammarPoint] { all.filter { $0.level == level } }

    /// Every grammar point, with its memory tricks attached.
    static let all: [GrammarPoint] = (core + more).map { p in
        var p = p
        p.tips += extraTips[p.id] ?? []
        return p
    }

    private static let core: [GrammarPoint] = [
        // MARK: HSK 1
        GrammarPoint(
            id: "g-shi", level: 1, title: "是 — to be", summary: "A 是 B: linking two nouns",
            explanation: "是 (shì) links a subject to a noun: “A is B”. It does not change form for person or tense.",
            examples: [
                .init(chinese: "我是学生。", pinyin: "Wǒ shì xuésheng.", english: "I am a student."),
                .init(chinese: "他是我的老师。", pinyin: "Tā shì wǒ de lǎoshī.", english: "He is my teacher."),
            ],
            commonMistake: "Don't use 是 before adjectives. Say 我很高兴 (I'm happy), not 我是高兴.",
            builders: [
                .init(tokens: ["我", "是", "中国人"], english: "I am Chinese."),
                .init(tokens: ["她", "是", "我的", "妈妈"], english: "She is my mom."),
            ],
            blanks: [
                .init(sentence: "他＿＿医生。", options: ["是", "有", "在", "很"], answer: "是", english: "He is a doctor."),
                .init(sentence: "这＿＿我的电脑。", options: ["很", "是", "吗", "不"], answer: "是", english: "This is my computer."),
            ]),
        GrammarPoint(
            id: "g-bu-mei", level: 1, title: "不 vs 没", summary: "Two ways to say “not”",
            explanation: "不 (bù) negates the present, future and habits. 没 (méi) negates 有 and things that did not happen in the past.",
            examples: [
                .init(chinese: "我不喝咖啡。", pinyin: "Wǒ bù hē kāfēi.", english: "I don't drink coffee."),
                .init(chinese: "我没有钱。", pinyin: "Wǒ méiyǒu qián.", english: "I don't have money."),
            ],
            commonMistake: "Never say 不有. The negative of 有 is always 没有.",
            builders: [
                .init(tokens: ["我", "不", "喝", "茶"], english: "I don't drink tea."),
                .init(tokens: ["他", "没", "有", "手机"], english: "He doesn't have a phone."),
            ],
            blanks: [
                .init(sentence: "我＿＿有时间。", options: ["不", "没", "吗", "了"], answer: "没", english: "I don't have time."),
                .init(sentence: "我明天＿＿去。", options: ["没", "不", "了", "吗"], answer: "不", english: "I'm not going tomorrow."),
            ]),
        GrammarPoint(
            id: "g-ma", level: 1, title: "吗 questions", summary: "Turn a statement into a yes/no question",
            explanation: "Add 吗 (ma) to the end of a statement to make a yes/no question. The word order does not change.",
            examples: [
                .init(chinese: "你是学生吗？", pinyin: "Nǐ shì xuésheng ma?", english: "Are you a student?"),
                .init(chinese: "你喝茶吗？", pinyin: "Nǐ hē chá ma?", english: "Do you drink tea?"),
            ],
            commonMistake: "Don't add 吗 to a question that already has a question word: 你叫什么名字？ (no 吗).",
            builders: [
                .init(tokens: ["你", "喝", "咖啡", "吗"], english: "Do you drink coffee?"),
                .init(tokens: ["他", "是", "老师", "吗"], english: "Is he a teacher?"),
            ],
            blanks: [
                .init(sentence: "你是中国人＿＿？", options: ["吗", "的", "了", "在"], answer: "吗", english: "Are you Chinese?"),
                .init(sentence: "你有电脑＿＿？", options: ["不", "吗", "是", "很"], answer: "吗", english: "Do you have a computer?"),
            ]),
        GrammarPoint(
            id: "g-zai", level: 1, title: "在 — location", summary: "Saying where someone or something is",
            explanation: "在 (zài) + place says where something is. Before another verb, 在 + place shows where the action happens.",
            examples: [
                .init(chinese: "我在家。", pinyin: "Wǒ zài jiā.", english: "I'm at home."),
                .init(chinese: "他在北京工作。", pinyin: "Tā zài Běijīng gōngzuò.", english: "He works in Beijing."),
            ],
            commonMistake: "The place comes before the verb: 我在北京工作, not 我工作在北京.",
            builders: [
                .init(tokens: ["我", "在", "饭店", "吃饭"], english: "I eat at a restaurant."),
                .init(tokens: ["妈妈", "在", "家"], english: "Mom is at home."),
            ],
            blanks: [
                .init(sentence: "我的手机＿＿桌子上。", options: ["在", "是", "有", "去"], answer: "在", english: "My phone is on the table."),
                .init(sentence: "他＿＿学校学习。", options: ["是", "在", "很", "吗"], answer: "在", english: "He studies at school."),
            ]),
        GrammarPoint(
            id: "g-le", level: 1, title: "了 — completed action", summary: "Showing something has happened",
            explanation: "了 (le) after a verb shows the action is completed. At the end of a sentence it can also show a change of situation.",
            examples: [
                .init(chinese: "我买了一本书。", pinyin: "Wǒ mǎi le yì běn shū.", english: "I bought a book."),
                .init(chinese: "她回家了。", pinyin: "Tā huí jiā le.", english: "She went home."),
            ],
            commonMistake: "To negate a past action, use 没 and drop 了: 我没去, not 我没去了.",
            builders: [
                .init(tokens: ["我", "买", "了", "一本", "书"], english: "I bought a book."),
                .init(tokens: ["她", "回家", "了"], english: "She went home."),
            ],
            blanks: [
                .init(sentence: "我昨天看＿＿一个电影。", options: ["了", "吗", "的", "在"], answer: "了", english: "I watched a movie yesterday."),
                .init(sentence: "他去北京＿＿。", options: ["吗", "了", "不", "很"], answer: "了", english: "He has gone to Beijing."),
            ]),
        GrammarPoint(
            id: "g-measure", level: 1, title: "Measure words", summary: "Number + measure word + noun",
            explanation: "Between a number (or 这/那) and a noun you need a measure word. 个 is the most common; 本 is for books, 杯 for cups of drinks.",
            examples: [
                .init(chinese: "三本书", pinyin: "sān běn shū", english: "three books"),
                .init(chinese: "两杯茶", pinyin: "liǎng bēi chá", english: "two cups of tea"),
            ],
            commonMistake: "Use 两, not 二, before a measure word: 两个人, not 二个人.",
            builders: [
                .init(tokens: ["我", "有", "两", "本", "书"], english: "I have two books."),
                .init(tokens: ["请", "给我", "一杯", "茶"], english: "Please give me a cup of tea."),
            ],
            blanks: [
                .init(sentence: "我有三＿＿朋友。", options: ["个", "本", "杯", "只"], answer: "个", english: "I have three friends."),
                .init(sentence: "他买了两＿＿书。", options: ["杯", "个", "本", "只"], answer: "本", english: "He bought two books."),
            ]),

        // MARK: HSK 2
        GrammarPoint(
            id: "g-bi", level: 2, title: "比 — comparisons", summary: "A 比 B + adjective",
            explanation: "To say A is more … than B, use A 比 B + adjective.",
            examples: [
                .init(chinese: "他比我高。", pinyin: "Tā bǐ wǒ gāo.", english: "He is taller than me."),
                .init(chinese: "今天比昨天冷。", pinyin: "Jīntiān bǐ zuótiān lěng.", english: "Today is colder than yesterday."),
            ],
            commonMistake: "Don't put 很 in a 比 sentence: 他比我很高 is wrong. Say 他比我高 or 他比我高多了.",
            builders: [
                .init(tokens: ["这个", "比", "那个", "便宜"], english: "This one is cheaper than that one."),
                .init(tokens: ["哥哥", "比", "我", "大"], english: "My older brother is older than me."),
            ],
            blanks: [
                .init(sentence: "他＿＿我高。", options: ["比", "很", "是", "在"], answer: "比", english: "He is taller than me."),
                .init(sentence: "北京＿＿上海冷。", options: ["在", "比", "和", "是"], answer: "比", english: "Beijing is colder than Shanghai."),
            ]),
        GrammarPoint(
            id: "g-time", level: 2, title: "Time words go first", summary: "Subject + time + verb",
            explanation: "In Chinese, time expressions come before the verb, usually right after the subject (or at the very start).",
            examples: [
                .init(chinese: "我明天去北京。", pinyin: "Wǒ míngtiān qù Běijīng.", english: "I'm going to Beijing tomorrow."),
                .init(chinese: "我早上七点起床。", pinyin: "Wǒ zǎoshang qī diǎn qǐ chuáng.", english: "I get up at 7 in the morning."),
            ],
            commonMistake: "Don't put the time at the end like in English: 我去北京明天 is wrong.",
            builders: [
                .init(tokens: ["我", "明天", "去", "学校"], english: "I'm going to school tomorrow."),
                .init(tokens: ["他", "每天", "早上", "跑步"], english: "He runs every morning."),
            ],
            blanks: [
                .init(sentence: "我＿＿去学校。", options: ["明天", "了", "吗", "个"], answer: "明天", english: "I'm going to school tomorrow."),
                .init(sentence: "他＿＿七点吃早饭。", options: ["很", "早上", "比", "吗"], answer: "早上", english: "He has breakfast at 7 in the morning."),
            ]),
        GrammarPoint(
            id: "g-de", level: 2, title: "得 — how well", summary: "Verb + 得 + adjective",
            explanation: "Use verb + 得 (de) + adjective to describe how an action is done.",
            examples: [
                .init(chinese: "她唱得很好。", pinyin: "Tā chàng de hěn hǎo.", english: "She sings well."),
                .init(chinese: "他跑得很快。", pinyin: "Tā pǎo de hěn kuài.", english: "He runs fast."),
            ],
            commonMistake: "With an object, repeat the verb: 她跳舞跳得很好, not 她跳舞得很好.",
            builders: [
                .init(tokens: ["她", "说", "得", "很", "快"], english: "She speaks fast."),
                .init(tokens: ["他", "写", "得", "很", "好"], english: "He writes well."),
            ],
            blanks: [
                .init(sentence: "他跑＿＿很快。", options: ["得", "的", "了", "在"], answer: "得", english: "He runs fast."),
                .init(sentence: "你说＿＿太快了。", options: ["吗", "得", "是", "不"], answer: "得", english: "You speak too fast."),
            ]),
        GrammarPoint(
            id: "g-suiran", level: 2, title: "虽然…但是…", summary: "Although … (but) …",
            explanation: "虽然 (suīrán) introduces a fact, and 但是 (dànshì) introduces the contrasting result. Chinese uses both together.",
            examples: [
                .init(chinese: "虽然很累，但是我很高兴。", pinyin: "Suīrán hěn lèi, dànshì wǒ hěn gāoxìng.", english: "Although I'm tired, I'm happy."),
                .init(chinese: "虽然很贵，但是很好吃。", pinyin: "Suīrán hěn guì, dànshì hěn hǎochī.", english: "Although it's expensive, it's delicious."),
            ],
            commonMistake: "Unlike English, it's natural to use both words: 虽然…但是… together.",
            builders: [
                .init(tokens: ["虽然", "很贵", "但是", "很好吃"], english: "Although it's expensive, it's delicious."),
                .init(tokens: ["虽然", "下雨", "但是", "他", "来了"], english: "Although it rained, he came."),
            ],
            blanks: [
                .init(sentence: "虽然下雨了，＿＿我们还是去了。", options: ["但是", "因为", "所以", "如果"], answer: "但是", english: "Although it rained, we still went."),
                .init(sentence: "＿＿汉语很难，但是很有意思。", options: ["因为", "虽然", "所以", "可是"], answer: "虽然", english: "Although Chinese is hard, it's interesting."),
            ]),

        // MARK: HSK 3
        GrammarPoint(
            id: "g-ba", level: 3, title: "把 sentences", summary: "Subject + 把 + object + verb + result",
            explanation: "把 (bǎ) moves the object before the verb to show what happens to it. The verb must be followed by something (a result, direction, 了…).",
            examples: [
                .init(chinese: "我把作业做完了。", pinyin: "Wǒ bǎ zuòyè zuò wán le.", english: "I finished my homework."),
                .init(chinese: "请把门关上。", pinyin: "Qǐng bǎ mén guān shang.", english: "Please close the door."),
            ],
            commonMistake: "The verb can't stand alone: 我把饭吃 is wrong. Say 我把饭吃了.",
            builders: [
                .init(tokens: ["请", "把", "门", "关上"], english: "Please close the door."),
                .init(tokens: ["我", "把", "书", "放在", "桌子上"], english: "I put the book on the table."),
            ],
            blanks: [
                .init(sentence: "请＿＿窗户打开。", options: ["把", "被", "比", "给"], answer: "把", english: "Please open the window."),
                .init(sentence: "他＿＿手机忘在家里了。", options: ["比", "把", "在", "给"], answer: "把", english: "He left his phone at home."),
            ]),
        GrammarPoint(
            id: "g-yuelaiyue", level: 3, title: "越来越", summary: "More and more …",
            explanation: "越来越 (yuè lái yuè) + adjective describes something increasing over time.",
            examples: [
                .init(chinese: "天气越来越冷了。", pinyin: "Tiānqì yuè lái yuè lěng le.", english: "The weather is getting colder and colder."),
                .init(chinese: "他的汉语越来越好。", pinyin: "Tā de Hànyǔ yuè lái yuè hǎo.", english: "His Chinese is getting better and better."),
            ],
            commonMistake: "Don't add 很 or 非常 after 越来越: 越来越很好 is wrong.",
            builders: [
                .init(tokens: ["天气", "越来越", "热", "了"], english: "It's getting hotter and hotter."),
                .init(tokens: ["她", "越来越", "漂亮"], english: "She's getting more and more beautiful."),
            ],
            blanks: [
                .init(sentence: "我的汉语＿＿好了。", options: ["越来越", "比", "得", "把"], answer: "越来越", english: "My Chinese is getting better and better."),
                .init(sentence: "这里的人＿＿多。", options: ["把", "越来越", "被", "了"], answer: "越来越", english: "There are more and more people here."),
            ]),
        GrammarPoint(
            id: "g-yibian", level: 3, title: "一边…一边…", summary: "Doing two things at once",
            explanation: "一边 A 一边 B means doing A and B at the same time.",
            examples: [
                .init(chinese: "他一边吃饭一边看电视。", pinyin: "Tā yìbiān chī fàn yìbiān kàn diànshì.", english: "He watches TV while eating."),
                .init(chinese: "我们一边走一边说。", pinyin: "Wǒmen yìbiān zǒu yìbiān shuō.", english: "We talk as we walk."),
            ],
            commonMistake: "Both actions need 一边 in front: 一边唱歌一边跳舞.",
            builders: [
                .init(tokens: ["她", "一边", "唱歌", "一边", "跳舞"], english: "She sings while dancing."),
                .init(tokens: ["我", "一边", "听", "音乐", "一边", "学习"], english: "I study while listening to music."),
            ],
            blanks: [
                .init(sentence: "他＿＿走路一边打电话。", options: ["一边", "一起", "一样", "一下"], answer: "一边", english: "He talks on the phone while walking."),
                .init(sentence: "妈妈一边做饭＿＿听音乐。", options: ["一起", "一下", "一边", "一样"], answer: "一边", english: "Mom listens to music while cooking."),
            ]),
    ]
}
