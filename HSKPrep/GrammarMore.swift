import Foundation

/// More grammar points (original teaching content) and memory tricks.
extension GrammarStore {
    /// Memory tricks for the original grammar points (by id).
    static let extraTips: [String: [String]] = [
        "g-shi": ["Think of 是 as an “=” sign between two nouns: 我 = 学生. If the right side is an adjective, use 很 instead."],
        "g-bu-mei": ["Quick test: did it already (not) happen, or is it about 有? → 没. Everything else → 不.",
                     "没 can stand alone as an answer: 你去了吗？— 没去。"],
        "g-ma": ["吗 turns any statement into a yes/no question — answer by repeating the verb: 你喝茶吗？— 喝。/ 不喝。"],
        "g-zai": ["Order trick: WHO + WHERE + DO. 我 + 在家 + 吃饭. The place always sits before the action."],
        "g-le": ["Two 了s: after the verb = done (我买了书); at the end = something has changed (下雨了 — it's raining now)."],
        "g-measure": ["When in doubt, 个 is understood almost everywhere — but learn 本 (books), 杯 (cups), 张 (flat things), 件 (clothes, matters)."],
        "g-bi": ["Formula: A 比 B + adjective (+ how much). 他比我高 / 他比我高五厘米 / 他比我高多了."],
        "g-time": ["Big before small: 2026年10月10号上午九点 — year, month, day, part of day, hour."],
        "g-de": ["得 = “how well”: look for it right after a verb. The answer to 他说得怎么样？ is 他说得很好。"],
        "g-suiran": ["Chinese likes pairs of linking words: 虽然…但是, 因为…所以, 如果…就, 不但…而且."],
        "g-ba": ["Use 把 when you DO something TO an object and it ends somewhere or changes: 把书放在桌子上, 把作业做完."],
        "g-yuelaiyue": ["越来越 = more and more over time. 越 A 越 B = the more A, the more B: 越学越喜欢."],
        "g-yibian": ["Both actions must be things one person can do at the same time: 一边听音乐一边跑步 ✓."],
    ]

    static let more: [GrammarPoint] = [
        // MARK: HSK 1
        GrammarPoint(
            id: "g-ne", level: 1, title: "呢 — and you? / where is?", summary: "Short follow-up questions",
            explanation: "Put 呢 (ne) after a noun to ask “what about…?” or “where is…?”. At the end of a sentence with 在 it can also show an action is going on.",
            examples: [
                .init(chinese: "我很好，你呢？", pinyin: "Wǒ hěn hǎo, nǐ ne?", english: "I'm fine, and you?"),
                .init(chinese: "我的手机呢？", pinyin: "Wǒ de shǒujī ne?", english: "Where's my phone?"),
                .init(chinese: "他在看书呢。", pinyin: "Tā zài kàn shū ne.", english: "He's reading."),
            ],
            commonMistake: "呢 is not for yes/no questions. Say 你好吗？, not 你好呢？",
            builders: [
                .init(tokens: ["他", "在", "睡觉", "呢"], english: "He's sleeping."),
                .init(tokens: ["你的", "手机", "呢"], english: "Where's your phone?"),
            ],
            blanks: [
                .init(sentence: "我喜欢喝茶，你＿＿？", options: ["呢", "吗", "的", "了"], answer: "呢", english: "I like tea, what about you?"),
                .init(sentence: "我的书＿＿？", options: ["吧", "呢", "了", "个"], answer: "呢", english: "Where's my book?"),
            ],
            tips: ["Echo trick: answer a question, then bounce it back with 你呢？ — the most useful two syllables in a conversation."]),
        GrammarPoint(
            id: "g-ye-dou", level: 1, title: "也 and 都 — also, all", summary: "Adverbs go before the verb",
            explanation: "也 (yě, also) and 都 (dōu, all/both) always go after the subject and before the verb — never at the start or end like in English.",
            examples: [
                .init(chinese: "我也是学生。", pinyin: "Wǒ yě shì xuésheng.", english: "I'm a student too."),
                .init(chinese: "我们都喜欢中国菜。", pinyin: "Wǒmen dōu xǐhuan Zhōngguó cài.", english: "We all like Chinese food."),
            ],
            commonMistake: "Don't put 也 first: 也我去 ✗ → 我也去 ✓. With both, the order is 也都: 我们也都是学生.",
            builders: [
                .init(tokens: ["我", "也", "喜欢", "喝茶"], english: "I also like drinking tea."),
                .init(tokens: ["我们", "都", "是", "学生"], english: "We are all students."),
            ],
            blanks: [
                .init(sentence: "他是老师，我＿＿是老师。", options: ["也", "都", "很", "不"], answer: "也", english: "He's a teacher, and I'm a teacher too."),
                .init(sentence: "我们＿＿是中国人。", options: ["和", "都", "很", "吗"], answer: "都", english: "We are all Chinese."),
            ],
            tips: ["都 looks back at a group that came BEFORE it: 我和他都去 (both of us go)."]),
        GrammarPoint(
            id: "g-de-possessive", level: 1, title: "的 — 's and describing", summary: "Owner / description + 的 + noun",
            explanation: "的 (de) links an owner or a description to a noun, like English 's: 我的书 (my book), 妈妈的朋友 (mom's friend), 漂亮的衣服 (pretty clothes).",
            examples: [
                .init(chinese: "这是老师的书。", pinyin: "Zhè shì lǎoshī de shū.", english: "This is the teacher's book."),
                .init(chinese: "我喜欢漂亮的衣服。", pinyin: "Wǒ xǐhuan piàoliang de yīfu.", english: "I like pretty clothes."),
            ],
            commonMistake: "With close family and your own groups you can drop 的: 我妈妈, 我们学校 sound more natural than 我的妈妈.",
            builders: [
                .init(tokens: ["这", "是", "老师的", "书"], english: "This is the teacher's book."),
                .init(tokens: ["那", "是", "我", "朋友的", "电脑"], english: "That is my friend's computer."),
            ],
            blanks: [
                .init(sentence: "这是谁＿＿杯子？", options: ["的", "得", "地", "了"], answer: "的", english: "Whose cup is this?"),
                .init(sentence: "我喜欢漂亮＿＿衣服。", options: ["得", "的", "很", "吗"], answer: "的", english: "I like pretty clothes."),
            ],
            tips: ["的 before a NOUN, 得 after a VERB, 地 before a VERB — all three are read “de”."]),
        GrammarPoint(
            id: "g-ji-duoshao", level: 1, title: "几 vs 多少 — how many", summary: "Small numbers vs any number",
            explanation: "几 (jǐ) asks about small numbers (usually under 10) and needs a measure word: 几个人. 多少 (duōshao) works for any number and prices: 多少钱, 多少学生.",
            examples: [
                .init(chinese: "你家有几个人？", pinyin: "Nǐ jiā yǒu jǐ ge rén?", english: "How many people are in your family?"),
                .init(chinese: "这个多少钱？", pinyin: "Zhège duōshao qián?", english: "How much is this?"),
            ],
            commonMistake: "几 needs a measure word: 几个朋友, not 几朋友. Ask a child's age with 几岁, an adult's with 多大.",
            builders: [
                .init(tokens: ["你", "有", "几个", "朋友"], english: "How many friends do you have?"),
                .init(tokens: ["这个", "苹果", "多少", "钱"], english: "How much is this apple?"),
            ],
            blanks: [
                .init(sentence: "你女儿＿＿岁了？", options: ["几", "多少", "什么", "哪"], answer: "几", english: "How old is your daughter?"),
                .init(sentence: "你们学校有＿＿学生？", options: ["多少", "几", "谁", "哪儿"], answer: "多少", english: "How many students does your school have?"),
            ],
            tips: ["Time: 几点 (what time), 几号 (what date), 星期几 (which weekday) — all use 几."]),
        GrammarPoint(
            id: "g-hui-neng-xiang", level: 1, title: "会, 能, 想 — can, may, want", summary: "Three helping verbs",
            explanation: "会 (huì) = can because you LEARNED it (会说汉语) or 'will'. 能 (néng) = able / allowed right now (今天不能去). 想 (xiǎng) = would like to (想喝茶).",
            examples: [
                .init(chinese: "我会说一点儿汉语。", pinyin: "Wǒ huì shuō yìdiǎnr Hànyǔ.", english: "I can speak a little Chinese."),
                .init(chinese: "我今天不能去。", pinyin: "Wǒ jīntiān bù néng qù.", english: "I can't go today."),
                .init(chinese: "我想喝茶。", pinyin: "Wǒ xiǎng hē chá.", english: "I'd like to drink tea."),
            ],
            commonMistake: "Skills learned → 会: 我会游泳. Circumstances → 能: 我生病了，不能游泳.",
            builders: [
                .init(tokens: ["我", "会", "说", "汉语"], english: "I can speak Chinese."),
                .init(tokens: ["你", "想", "吃", "什么"], english: "What would you like to eat?"),
            ],
            blanks: [
                .init(sentence: "我＿＿说一点儿汉语。", options: ["会", "是", "在", "有"], answer: "会", english: "I can speak a little Chinese."),
                .init(sentence: "我今天有事，不＿＿去。", options: ["能", "是", "有", "在"], answer: "能", english: "I'm busy today and can't go."),
            ],
            tips: ["会 = know HOW, 能 = CAN right now, 想 = WANT. Ask yourself: learned? possible? wished?"]),
        GrammarPoint(
            id: "g-zai-doing", level: 1, title: "在 + verb — doing right now", summary: "Actions in progress",
            explanation: "在 (zài) before a VERB means the action is happening now. You can add 呢 at the end: 他在睡觉呢.",
            examples: [
                .init(chinese: "妈妈在做饭。", pinyin: "Māma zài zuò fàn.", english: "Mom is cooking."),
                .init(chinese: "他们在打电话呢。", pinyin: "Tāmen zài dǎ diànhuà ne.", english: "They're on the phone."),
            ],
            commonMistake: "在 + place = where; 在 + verb = doing now. Both can combine: 他在家看书 (he reads at home).",
            builders: [
                .init(tokens: ["妈妈", "在", "做饭"], english: "Mom is cooking."),
                .init(tokens: ["他们", "在", "打电话"], english: "They're on the phone."),
            ],
            blanks: [
                .init(sentence: "别说话，孩子＿＿睡觉呢。", options: ["在", "是", "有", "了"], answer: "在", english: "Don't talk, the child is sleeping."),
                .init(sentence: "你＿＿做什么？", options: ["在", "的", "很", "也"], answer: "在", english: "What are you doing?"),
            ],
            tips: ["正在 (zhèngzài) = 'right at this moment' — stronger than 在."]),

        // MARK: HSK 2
        GrammarPoint(
            id: "g-guo", level: 2, title: "过 — have ever done", summary: "Experience: verb + 过",
            explanation: "Verb + 过 (guo) says you have had the experience at some time: 我去过中国 (I've been to China). Negative: 没 + verb + 过.",
            examples: [
                .init(chinese: "我去过北京。", pinyin: "Wǒ qù guo Běijīng.", english: "I've been to Beijing."),
                .init(chinese: "他没学过汉语。", pinyin: "Tā méi xué guo Hànyǔ.", english: "He has never studied Chinese."),
            ],
            commonMistake: "Negative with 没, not 不: 我没去过, not 我不去过.",
            builders: [
                .init(tokens: ["我", "去过", "北京"], english: "I've been to Beijing."),
                .init(tokens: ["他", "没", "学过", "汉语"], english: "He has never studied Chinese."),
            ],
            blanks: [
                .init(sentence: "我看＿＿这个电影，很好看。", options: ["过", "着", "得", "地"], answer: "过", english: "I've seen this movie — it's great."),
                .init(sentence: "你吃＿＿中国菜吗？", options: ["得", "过", "地", "着"], answer: "过", english: "Have you ever eaten Chinese food?"),
            ],
            tips: ["了 = it happened (this time). 过 = you have the experience (at least once in life)."]),
        GrammarPoint(
            id: "g-yijing", level: 2, title: "已经…了 — already", summary: "Something is already done",
            explanation: "已经 (yǐjīng) before the verb + 了 at the end means something has already happened.",
            examples: [
                .init(chinese: "我已经吃饭了。", pinyin: "Wǒ yǐjīng chī fàn le.", english: "I've already eaten."),
                .init(chinese: "电影已经开始了。", pinyin: "Diànyǐng yǐjīng kāishǐ le.", english: "The movie has already started."),
            ],
            commonMistake: "Don't forget 了 at the end: 我已经吃饭了 ✓, 我已经吃饭 ✗ (sounds unfinished).",
            builders: [
                .init(tokens: ["我", "已经", "到", "了"], english: "I've already arrived."),
                .init(tokens: ["电影", "已经", "开始", "了"], english: "The movie has already started."),
            ],
            blanks: [
                .init(sentence: "我＿＿到机场了。", options: ["已经", "正在", "因为", "但是"], answer: "已经", english: "I've already arrived at the airport."),
                .init(sentence: "他已经回家＿＿。", options: ["了", "吗", "的", "得"], answer: "了", english: "He has already gone home."),
            ],
            tips: ["已经 + 了 work as a pair, like the two halves of a sandwich."]),
        GrammarPoint(
            id: "g-yaole", level: 2, title: "要…了 / 快…了 — about to", summary: "Something will happen soon",
            explanation: "要…了, 快…了 and 快要…了 mean something is about to happen: 要下雨了 (it's about to rain).",
            examples: [
                .init(chinese: "要下雨了。", pinyin: "Yào xià yǔ le.", english: "It's going to rain."),
                .init(chinese: "火车快要开了。", pinyin: "Huǒchē kuài yào kāi le.", english: "The train is about to leave."),
            ],
            commonMistake: "With an exact time, use 就要…了, not 快要: 明天就要考试了 ✓, 明天快要考试了 ✗.",
            builders: [
                .init(tokens: ["要", "下雨", "了"], english: "It's about to rain."),
                .init(tokens: ["电影", "快", "开始", "了"], english: "The movie is about to start."),
            ],
            blanks: [
                .init(sentence: "快点儿，火车＿＿开了！", options: ["要", "过", "在", "着"], answer: "要", english: "Hurry, the train is about to leave!"),
                .init(sentence: "我们快＿＿考试了。", options: ["要", "过", "得", "在"], answer: "要", english: "We're about to have our exam."),
            ],
            tips: ["Hear 了 at the end + 要/快 before the verb → it hasn't happened yet, but it's coming."]),
        GrammarPoint(
            id: "g-haishi", level: 2, title: "还是 vs 或者 — or", summary: "Questions vs statements",
            explanation: "Use 还是 (háishi) in questions offering a choice: 你喝茶还是喝咖啡？ Use 或者 (huòzhě) in statements: 星期六或者星期天都可以.",
            examples: [
                .init(chinese: "你喝茶还是喝咖啡？", pinyin: "Nǐ hē chá háishi hē kāfēi?", english: "Do you drink tea or coffee?"),
                .init(chinese: "我们星期六或者星期天去。", pinyin: "Wǒmen xīngqīliù huòzhě xīngqītiān qù.", english: "We'll go on Saturday or Sunday."),
            ],
            commonMistake: "No 吗 with 还是: 你去还是不去？ ✓, 你去还是不去吗？ ✗.",
            builders: [
                .init(tokens: ["你", "喝茶", "还是", "喝咖啡"], english: "Do you drink tea or coffee?"),
                .init(tokens: ["周末", "我", "看书", "或者", "跑步"], english: "At weekends I read or go running."),
            ],
            blanks: [
                .init(sentence: "你想去北京＿＿上海？", options: ["还是", "或者", "和", "但是"], answer: "还是", english: "Do you want to go to Beijing or Shanghai?"),
                .init(sentence: "我们可以坐飞机＿＿坐火车去。", options: ["或者", "还是", "因为", "所以"], answer: "或者", english: "We can go by plane or by train."),
            ],
            tips: ["还是 has a question mark hidden inside it; 或者 never asks."]),
        GrammarPoint(
            id: "g-zui", level: 2, title: "最 — the most", summary: "Superlatives",
            explanation: "最 (zuì) + adjective/verb = the most: 最高 (tallest), 最喜欢 (like most). Add 的 before a noun: 最大的教室.",
            examples: [
                .init(chinese: "我最喜欢夏天。", pinyin: "Wǒ zuì xǐhuan xiàtiān.", english: "I like summer the most."),
                .init(chinese: "他是我们班最高的。", pinyin: "Tā shì wǒmen bān zuì gāo de.", english: "He's the tallest in our class."),
            ],
            commonMistake: "Don't add 很 to 最: 最好 ✓, 很最好 ✗.",
            builders: [
                .init(tokens: ["我", "最", "喜欢", "夏天"], english: "I like summer the most."),
                .init(tokens: ["这个", "最", "便宜"], english: "This one is the cheapest."),
            ],
            blanks: [
                .init(sentence: "这是我们学校＿＿大的教室。", options: ["最", "比", "很", "太"], answer: "最", english: "This is the biggest classroom in our school."),
                .init(sentence: "我＿＿喜欢的颜色是红色。", options: ["比", "最", "都", "也"], answer: "最", english: "My favourite colour is red."),
            ],
            tips: ["最好 also means 'you'd better': 你最好早点儿睡觉."]),
        GrammarPoint(
            id: "g-jiu", level: 2, title: "就 — right away / so early", summary: "Sooner than expected",
            explanation: "就 (jiù) before a verb shows something happens soon, early or easily: 我马上就来 (I'm coming right away), 他六点就起床了 (he got up as early as six).",
            examples: [
                .init(chinese: "我马上就来。", pinyin: "Wǒ mǎshàng jiù lái.", english: "I'm coming right away."),
                .init(chinese: "走路五分钟就到了。", pinyin: "Zǒu lù wǔ fēnzhōng jiù dào le.", english: "It only takes five minutes on foot."),
            ],
            commonMistake: "就 = earlier/sooner than expected; 才 = later than expected: 他十点才来 (he didn't come until ten).",
            builders: [
                .init(tokens: ["我", "马上", "就", "来"], english: "I'm coming right away."),
                .init(tokens: ["他", "六点", "就", "起床", "了"], english: "He got up as early as six."),
            ],
            blanks: [
                .init(sentence: "别着急，我马上＿＿到。", options: ["就", "才", "也", "都"], answer: "就", english: "Don't worry, I'll be there right away."),
                .init(sentence: "学校很近，走路五分钟＿＿到了。", options: ["就", "才", "还", "再"], answer: "就", english: "The school is close, five minutes on foot."),
            ],
            tips: ["就 is fast and happy; 才 is slow and a bit annoyed."]),
        GrammarPoint(
            id: "g-yixia", level: 2, title: "一下 — just a bit", summary: "Softening a request",
            explanation: "Verb + 一下 (yíxià) makes an action short and polite: 等一下 (wait a moment), 介绍一下 (let me introduce). Repeating the verb does the same: 看看, 试试.",
            examples: [
                .init(chinese: "请等一下。", pinyin: "Qǐng děng yíxià.", english: "Please wait a moment."),
                .init(chinese: "我来介绍一下。", pinyin: "Wǒ lái jièshào yíxià.", english: "Let me introduce (them)."),
            ],
            commonMistake: "一下 goes after the verb: 看一下 ✓, 一下看 ✗.",
            builders: [
                .init(tokens: ["请", "等", "一下"], english: "Please wait a moment."),
                .init(tokens: ["我", "来", "介绍", "一下"], english: "Let me introduce (them)."),
            ],
            blanks: [
                .init(sentence: "你能帮我看＿＿吗？", options: ["一下", "一次", "一边", "一起"], answer: "一下", english: "Can you take a look for me?"),
                .init(sentence: "我们休息＿＿吧。", options: ["一下", "一样", "一共", "一直"], answer: "一下", english: "Let's take a short break."),
            ],
            tips: ["Sounds more polite instantly: 你来 → 你来一下."]),

        // MARK: HSK 3
        GrammarPoint(
            id: "g-bei", level: 3, title: "被 — passive", summary: "Something happened TO the subject",
            explanation: "Object + 被 + (doer) + verb + result: 我的手机被弟弟拿走了. Often used when something unwanted happened.",
            examples: [
                .init(chinese: "蛋糕被吃完了。", pinyin: "Dàngāo bèi chī wán le.", english: "The cake has been eaten up."),
                .init(chinese: "我的书被他拿走了。", pinyin: "Wǒ de shū bèi tā ná zǒu le.", english: "My book was taken by him."),
            ],
            commonMistake: "Like 把, the verb needs something after it: 被吃了 / 被吃完了 ✓, 被吃 ✗.",
            builders: [
                .init(tokens: ["蛋糕", "被", "吃完", "了"], english: "The cake has been eaten up."),
                .init(tokens: ["我的", "书", "被", "他", "拿走", "了"], english: "My book was taken by him."),
            ],
            blanks: [
                .init(sentence: "我的伞＿＿朋友借走了。", options: ["被", "把", "比", "给"], answer: "被", english: "My umbrella was borrowed by a friend."),
                .init(sentence: "门＿＿风刮开了。", options: ["被", "把", "在", "对"], answer: "被", english: "The door was blown open by the wind."),
            ],
            tips: ["把 = I did it to the thing. 被 = the thing had it done to it. Same verb, opposite direction."]),
        GrammarPoint(
            id: "g-chule", level: 3, title: "除了…以外 — except / besides", summary: "Two meanings, chosen by 都 or 还",
            explanation: "除了 A (以外)，…都… = except A. 除了 A (以外)，…还/也… = besides A, also.",
            examples: [
                .init(chinese: "除了小王以外，大家都来了。", pinyin: "Chúle Xiǎo Wáng yǐwài, dàjiā dōu lái le.", english: "Everyone came except Xiao Wang."),
                .init(chinese: "除了汉语，我还学数学。", pinyin: "Chúle Hànyǔ, wǒ hái xué shùxué.", english: "Besides Chinese, I also study maths."),
            ],
            commonMistake: "Watch the second half: 都 → excluding, 还/也 → including.",
            builders: [
                .init(tokens: ["除了", "他", "大家", "都", "来了"], english: "Everyone came except him."),
                .init(tokens: ["除了", "茶", "我", "还", "喜欢", "咖啡"], english: "Besides tea, I also like coffee."),
            ],
            blanks: [
                .init(sentence: "＿＿星期天，我每天都上班。", options: ["除了", "虽然", "如果", "因为"], answer: "除了", english: "I work every day except Sunday."),
                .init(sentence: "除了跑步，我＿＿喜欢游泳。", options: ["还", "都", "就", "才"], answer: "还", english: "Besides running, I also like swimming."),
            ],
            tips: ["Look ahead: the little word 都 or 还 later in the sentence decides the meaning."]),
        GrammarPoint(
            id: "g-ruguo", level: 3, title: "如果…就 — if…then", summary: "Conditions",
            explanation: "如果 (rúguǒ) introduces the condition; 就 (jiù) comes before the verb of the result.",
            examples: [
                .init(chinese: "如果明天下雨，我们就不去了。", pinyin: "Rúguǒ míngtiān xià yǔ, wǒmen jiù bú qù le.", english: "If it rains tomorrow, we won't go."),
                .init(chinese: "如果你累了，就休息吧。", pinyin: "Rúguǒ nǐ lèi le, jiù xiūxi ba.", english: "If you're tired, take a rest."),
            ],
            commonMistake: "就 goes after the subject of the second part: 我们就不去, not 就我们不去.",
            builders: [
                .init(tokens: ["如果", "你", "累了", "就", "休息", "吧"], english: "If you're tired, take a rest."),
                .init(tokens: ["如果", "有", "时间", "我", "就", "去"], english: "If I have time, I'll go."),
            ],
            blanks: [
                .init(sentence: "＿＿你有问题，就问老师。", options: ["如果", "虽然", "因为", "除了"], answer: "如果", english: "If you have a question, ask the teacher."),
                .init(sentence: "如果明天不下雨，我们＿＿去爬山。", options: ["就", "才", "都", "还"], answer: "就", english: "If it doesn't rain tomorrow, we'll go hiking."),
            ],
            tips: ["The condition always comes FIRST in Chinese — the opposite of English 'I'll go if…'."]),
        GrammarPoint(
            id: "g-youyou", level: 3, title: "又…又… — both…and…", summary: "Two qualities at once",
            explanation: "又 A 又 B describes two qualities or actions together: 又便宜又好吃 (cheap and tasty).",
            examples: [
                .init(chinese: "这个苹果又大又甜。", pinyin: "Zhège píngguǒ yòu dà yòu tián.", english: "This apple is big and sweet."),
                .init(chinese: "她又聪明又漂亮。", pinyin: "Tā yòu cōngming yòu piàoliang.", english: "She's smart and pretty."),
            ],
            commonMistake: "Both qualities should be the same kind — both good or both bad: 又便宜又好 ✓, 又便宜又难吃 sounds odd.",
            builders: [
                .init(tokens: ["这家", "饭馆", "又", "便宜", "又", "好吃"], english: "This restaurant is cheap and tasty."),
                .init(tokens: ["他", "又", "高", "又", "瘦"], english: "He's tall and thin."),
            ],
            blanks: [
                .init(sentence: "这件衣服＿＿便宜又好看。", options: ["又", "也", "还", "都"], answer: "又", english: "This piece of clothing is cheap and good-looking."),
                .init(sentence: "这里的东西又贵＿＿不好。", options: ["又", "也", "就", "很"], answer: "又", english: "The things here are expensive and not good."),
            ],
            tips: ["No 很 inside 又…又…: 又很大 ✗."]),
        GrammarPoint(
            id: "g-xian", level: 3, title: "先…然后… — first…then…", summary: "Ordering actions",
            explanation: "先 (xiān) before the first action, 然后 (ránhòu) at the start of the next one. 再 can also mean 'then (later)'.",
            examples: [
                .init(chinese: "我先洗手，然后吃饭。", pinyin: "Wǒ xiān xǐ shǒu, ránhòu chī fàn.", english: "I wash my hands first, then eat."),
                .init(chinese: "你先做作业，然后再玩儿。", pinyin: "Nǐ xiān zuò zuòyè, ránhòu zài wánr.", english: "Do your homework first, then play."),
            ],
            commonMistake: "先 goes after the subject and before the verb: 我先去 ✓, 先我去 ✗.",
            builders: [
                .init(tokens: ["我们", "先", "吃饭", "然后", "去", "看电影"], english: "We'll eat first, then go to the movies."),
                .init(tokens: ["你", "先", "休息", "然后", "再", "工作"], english: "Rest first, then work."),
            ],
            blanks: [
                .init(sentence: "你＿＿做作业，然后再玩儿。", options: ["先", "又", "就", "才"], answer: "先", english: "Do your homework first, then play."),
                .init(sentence: "我先去银行，＿＿去超市。", options: ["然后", "因为", "如果", "虽然"], answer: "然后", english: "I'll go to the bank first, then the supermarket."),
            ],
            tips: ["Story chain: 先… 然后… 最后… (first… then… finally…)."]),
        GrammarPoint(
            id: "g-geng", level: 3, title: "更 — even more", summary: "Comparing with more strength",
            explanation: "更 (gèng) + adjective = even more: 今天比昨天更冷 (today is even colder than yesterday).",
            examples: [
                .init(chinese: "今天比昨天更冷。", pinyin: "Jīntiān bǐ zuótiān gèng lěng.", english: "Today is even colder than yesterday."),
                .init(chinese: "我更喜欢夏天。", pinyin: "Wǒ gèng xǐhuan xiàtiān.", english: "I prefer summer."),
            ],
            commonMistake: "In 比 sentences use 更 or 还, never 很 or 非常: 他比我更高 ✓, 他比我很高 ✗.",
            builders: [
                .init(tokens: ["他", "比", "我", "更", "高"], english: "He's even taller than me."),
                .init(tokens: ["我", "更", "喜欢", "夏天"], english: "I prefer summer."),
            ],
            blanks: [
                .init(sentence: "北京的冬天比上海＿＿冷。", options: ["更", "很", "非常", "太"], answer: "更", english: "Winter in Beijing is even colder than in Shanghai."),
                .init(sentence: "坐地铁比坐出租车＿＿方便。", options: ["更", "很", "太", "真"], answer: "更", english: "The subway is more convenient than a taxi."),
            ],
            tips: ["更 = “-er”, 最 = “-est”: 高 → 更高 → 最高."]),
        GrammarPoint(
            id: "g-cai", level: 3, title: "才 — not until / only then", summary: "Later than expected; 只有…才",
            explanation: "才 (cái) before a verb shows something happened late or needed a condition: 他十点才来 (he didn't come until ten). 只有 A 才 B = only if A, then B.",
            examples: [
                .init(chinese: "我等了一个小时，他才来。", pinyin: "Wǒ děng le yí ge xiǎoshí, tā cái lái.", english: "I waited an hour before he finally came."),
                .init(chinese: "只有多练习，才能说好汉语。", pinyin: "Zhǐyǒu duō liànxí, cái néng shuō hǎo Hànyǔ.", english: "Only by practising a lot can you speak Chinese well."),
            ],
            commonMistake: "No 了 after 才 for past events: 他十点才来 ✓, 他十点才来了 ✗.",
            builders: [
                .init(tokens: ["他", "八点", "才", "来"], english: "He didn't come until eight."),
                .init(tokens: ["只有", "多", "练习", "才能", "说好"], english: "Only with lots of practice can you speak well."),
            ],
            blanks: [
                .init(sentence: "我等了一个小时，他＿＿来。", options: ["才", "就", "都", "还"], answer: "才", english: "I waited an hour before he finally came."),
                .init(sentence: "＿＿多听多说，才能学好汉语。", options: ["只有", "如果", "虽然", "因为"], answer: "只有", english: "Only by listening and speaking a lot can you learn Chinese well."),
            ],
            tips: ["就 = early/easy 😊, 才 = late/hard 😩. 六点就起床 vs 十点才起床."]),
        GrammarPoint(
            id: "g-di", level: 3, title: "地 — how an action is done", summary: "Adjective + 地 + verb",
            explanation: "Adjective + 地 (de) + verb describes the manner of an action: 认真地学习 (study seriously), 高兴地说 (say happily).",
            examples: [
                .init(chinese: "他认真地复习了一个晚上。", pinyin: "Tā rènzhēn de fùxí le yí ge wǎnshang.", english: "He reviewed carefully all evening."),
                .init(chinese: "孩子们高兴地笑了。", pinyin: "Háizimen gāoxìng de xiào le.", english: "The children laughed happily."),
            ],
            commonMistake: "的 + noun, 得 after the verb, 地 before the verb: 认真地学习 / 学得很认真 / 认真的学生.",
            builders: [
                .init(tokens: ["孩子们", "高兴地", "笑了"], english: "The children laughed happily."),
                .init(tokens: ["他", "认真地", "复习"], english: "He reviews carefully."),
            ],
            blanks: [
                .init(sentence: "她很快＿＿走了出去。", options: ["地", "的", "得", "了"], answer: "地", english: "She walked out quickly."),
                .init(sentence: "他说汉语说＿＿很好。", options: ["得", "地", "的", "了"], answer: "得", english: "He speaks Chinese very well."),
            ],
            tips: ["地 contains 土 (earth): it's the ground the verb stands on — it comes BEFORE the verb."]),
    ]
}
