import SwiftUI

// MARK: - Radicals: the meaning-part of a character

/// Common radicals and what they usually hint at. Learning ~50 radicals makes
/// most HSK 1–3 characters easier to guess and remember.
enum Radicals {
    static let meanings: [String: String] = [
        "口": "mouth — speaking, eating, sounds (吃, 喝, 叫, 唱)",
        "亻": "person (他, 你, 们, 住, 休 = person resting by a tree)",
        "人": "person (个, 今, 会)",
        "木": "tree / wood (桌, 椅, 树, 机)",
        "扌": "hand — actions you do with your hands (打, 找, 拿, 把)",
        "氵": "water — liquids, rivers, washing (汉, 没, 洗, 游泳, 河)",
        "日": "sun / day — time and light (时, 明, 早, 晚, 昨)",
        "曰": "say / sun shape (最, 更, 书)",
        "讠": "speech — words and talking (说, 话, 语, 让, 请, 谁)",
        "艹": "grass / plants (茶, 菜, 苹, 花, 草, 药)",
        "女": "woman (妈, 姐, 妹, 她, 好 = woman + child)",
        "辶": "walking / movement (这, 还, 远, 近, 进, 道)",
        "目": "eye — seeing (看, 睛, 眼, 睡)",
        "心": "heart — feelings and thinking (想, 意, 思, 您, 息)",
        "忄": "heart (side form) — emotions (忙, 快, 慢, 情, 懂)",
        "纟": "silk / thread — textiles, connecting (红, 给, 绿, 结, 经)",
        "宀": "roof — buildings and homes (家, 字, 室, 安)",
        "土": "earth / ground (在, 地, 场, 坐)",
        "大": "big (天, 太, 大)",
        "灬": "fire (dots below) — heat, cooking (热, 点, 照, 熊)",
        "火": "fire (烧, 灯, 炒)",
        "刂": "knife (到, 别, 刚, 刷)",
        "又": "right hand / again (对, 欢, 双, 友)",
        "阝": "on the left: hill; on the right: city (院, 阴, 那, 都, 邻)",
        "子": "child (孩, 学, 字)",
        "囗": "enclosure — something surrounded (国, 回, 图, 园)",
        "月": "moon, or flesh/body (服, 朋, 期, 脸, 腿, 胖)",
        "⺼": "flesh / body part (脚, 腿, 脸)",
        "钅": "metal / gold (钱, 铅, 银, 钟)",
        "饣": "food (饭, 馆, 饿, 饱)",
        "巾": "cloth / towel (帮, 帽, 师)",
        "足": "foot — walking, running (跑, 跳, 踢, 路)",
        "⻊": "foot (跑, 跳, 踢, 路)",
        "冫": "ice — cold (冷, 冰, 冬)",
        "衤": "clothing (衬, 裤, 裙)",
        "衣": "clothing (衣, 袋)",
        "⺮": "bamboo (笔, 第, 答, 筷)",
        "竹": "bamboo (笔, 第, 筷)",
        "走": "walk / run (起, 越, 超)",
        "力": "strength (动, 加, 努)",
        "雨": "rain / weather (雪, 零, 雷)",
        "米": "rice (糖, 粉, 料)",
        "王": "jade / king (玩, 现, 理, 球)",
        "犭": "animal (dog-like) (狗, 猫, 猪)",
        "鸟": "bird (鸡, 鸭, 鸟)",
        "鱼": "fish (鱼, 鲜)",
        "马": "horse — often gives the sound 'ma' (妈, 吗, 骑)",
        "车": "vehicle (辆, 转, 轻)",
        "页": "head / page (题, 颜, 顾)",
        "贝": "shell = money in old China (贵, 费, 赢, 货)",
        "石": "stone (碗, 码, 研)",
        "疒": "sickness (病, 疼, 瘦)",
        "穴": "cave / hole (空, 窗, 穿)",
        "门": "door (问, 间, 闻)",
        "攵": "tap / action (教, 放, 数, 故)",
        "八": "eight / dividing (公, 分, 只)",
        "一": "one (一, 下, 上, 不)",
        "示": "show / spirit (票, 礼)",
        "礻": "spirit / ritual (礼, 祝, 视)",
        "白": "white (的, 百)",
        "小": "small (少, 尖)",
        "儿": "legs / son (先, 元, 兄)",
        "工": "work (左, 差)",
        "比": "compare (比)",
        "水": "water (水, 冰, 永)",
        "皿": "dish / container (盘, 盒)",
        "舟": "boat (船, 般)",
        "广": "shelter / building (店, 床, 座)",
        "尸": "body / roof (层, 屋, 局)",
        "耳": "ear (聪, 取)",
        "牛": "cow (牛, 物, 特)",
        "羊": "sheep (着, 美, 样)",
        "酉": "wine jar — drinks (酒, 醒)",
    ]

    /// A short memory hook for a word, based on the radical of its (first) character.
    static func hint(for word: Word) -> String? {
        guard let r = word.radical, let m = meanings[r] else { return nil }
        return "Radical \(r) = \(m)"
    }
}

// MARK: - Study tips

struct StudyTip: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let body: String
}

enum StudyTips {
    static let categories = ["Exam strategy", "Tones", "Characters", "Grammar shortcuts", "Memory tricks"]

    static let all: [StudyTip] = [
        // Exam strategy
        .init(category: "Exam strategy", title: "Read the options before the audio",
              body: "In the listening section, use the seconds before each recording to read the options. You'll know what to listen for — a time, a place, a person or a reason."),
        .init(category: "Exam strategy", title: "★ statements: look for the trap word",
              body: "True/false sentences are often almost the same as the recording, with one word changed: a number, a time (上午/下午), a negative (不/没) or a person. Check those first."),
        .init(category: "Exam strategy", title: "Questions about 男的 / 女的",
              body: "The question at the end asks about the man (男的) or the woman (女的). In dialogues the answer is often in what the OTHER person says, or in the second half."),
        .init(category: "Exam strategy", title: "Never leave a blank",
              body: "There's no penalty for wrong answers in HSK. If time is running out, guess — you have a 1 in 3 or 1 in 4 chance."),
        .init(category: "Exam strategy", title: "Fill-in-the-blank: check the word type",
              body: "Before choosing, ask: does the gap need a verb, a noun, an adjective or a measure word? After 很 comes an adjective; after a number comes a measure word; after 在 + place comes a verb."),
        .init(category: "Exam strategy", title: "Reading replies: match the question word",
              body: "谁 → a person, 哪儿 → a place, 什么时候/几点 → a time, 多少钱 → a price, 怎么 → a way (坐车, 走路), 为什么 → a reason (因为…)."),
        // Tones
        .init(category: "Tones", title: "The four tones in one picture",
              body: "1st ā high and flat — like singing a note. 2nd á rising — like asking 'what?'. 3rd ǎ low dip — like 'hmmm' when unsure. 4th à falling — like a firm 'No!'."),
        .init(category: "Tones", title: "Two 3rd tones in a row",
              body: "When two 3rd tones meet, the first one becomes a 2nd tone: 你好 nǐ hǎo is said ní hǎo, 很好 hěn hǎo → hén hǎo. The pinyin doesn't change on paper."),
        .init(category: "Tones", title: "不 bù changes before a 4th tone",
              body: "不 becomes 2nd tone before a 4th tone: 不是 bú shì, 不去 bú qù, 不对 bú duì. Otherwise it stays bù: 不好 bù hǎo, 不来 bù lái."),
        .init(category: "Tones", title: "一 yī changes too",
              body: "一 is yí before a 4th tone (一个 yí ge, 一样 yíyàng) and yì before 1st/2nd/3rd tones (一起 yìqǐ, 一年 yì nián). Alone or in numbers it stays yī (第一, 十一)."),
        .init(category: "Tones", title: "Practise tones in pairs",
              body: "Tones are easier to hear in two-syllable words. Learn one model word per pair, e.g. 飞机 (1-1), 中国 (1-2), 老师 (3-1), 电视 (4-4), and copy their melody."),
        .init(category: "Tones", title: "Light (neutral) tone",
              body: "Second syllables like 子, 们, 的, 吗, 呢 and repeated family words (妈妈, 爸爸) are short and light: māma, bàba, háizi. Don't stress them."),
        // Characters
        .init(category: "Characters", title: "Radicals tell you the meaning",
              body: "Most characters = a meaning part (radical) + a sound part. 氵 water → 河 river, 洗 wash, 游 swim. 讠 speech → 说, 话, 语. Check the 💡 radical hint on each flashcard."),
        .init(category: "Characters", title: "The sound part helps too",
              body: "马 mǎ gives the sound in 妈 mā, 吗 ma, 骂 mà. 青 qīng → 请 qǐng, 情 qíng, 晴 qíng, 清 qīng. The tone may change, but the sound is close."),
        .init(category: "Characters", title: "Tell look-alikes apart",
              body: "日 (sun) vs 目 (eye — one more line). 人 (person) vs 入 (enter). 买 mǎi (buy) vs 卖 mài (sell — 卖 has 十 on top: you sell, money goes up). 己 vs 已: 已经 is half-closed."),
        .init(category: "Characters", title: "Write it to remember it",
              body: "Write new characters 5 times while saying them out loud. Stroke order rule of thumb: top to bottom, left to right, horizontal before vertical, outside before inside, close the box last."),
        // Grammar shortcuts
        .init(category: "Grammar shortcuts", title: "Word order: Who – When – Where – Do – What",
              body: "我 明天 在家 看 书. Time and place come BEFORE the verb in Chinese — unlike English 'I read a book at home tomorrow'."),
        .init(category: "Grammar shortcuts", title: "Adjectives don't need 是",
              body: "Say 我很忙 (I'm busy), not 我是忙. 很 is often just a link and doesn't always mean 'very'."),
        .init(category: "Grammar shortcuts", title: "的, 得, 地 — all pronounced de",
              body: "的 before a noun (我的书, 漂亮的衣服). 得 after a verb, says how well (说得很好). 地 before a verb, says how it's done (认真地学习)."),
        .init(category: "Grammar shortcuts", title: "不 or 没?",
              body: "不 = present, future, habits, 'won't': 我不去. 没 = past or 'don't have': 我没去, 我没有钱. Never 不有."),
        .init(category: "Grammar shortcuts", title: "Questions keep statement order",
              body: "Put the question word where the answer would go: 你去哪儿? → 我去北京. 他是谁? → 他是我哥哥. Or add 吗 at the end of a statement."),
        // Memory tricks
        .init(category: "Memory tricks", title: "Story pictures for characters",
              body: "好 = 女 woman + 子 child → a mother with her child is 'good'. 休 = 亻 person + 木 tree → a person resting against a tree. 明 = 日 sun + 月 moon → 'bright'. 家 = 宀 roof + 豕 pig → home."),
        .init(category: "Memory tricks", title: "Learn words in small sets",
              body: "10 new words a day for 30 days = 300 words — almost all of HSK 1 + 2. Spaced repetition does the rest: review what's due before adding new cards."),
        .init(category: "Memory tricks", title: "Use the word in a sentence",
              body: "After learning a word, say one sentence about your own life with it: 我喜欢喝咖啡. Personal sentences stick much better than lists."),
        .init(category: "Memory tricks", title: "Shadow the audio",
              body: "Play a dialogue, pause after each line and repeat it with the same speed and melody. This trains listening and tones at the same time."),
    ]
}

// MARK: - Tips screen

struct StudyTipsView: View {
    @State private var category = StudyTips.categories[0]

    var body: some View {
        List {
            Section {
                Picker("Topic", selection: $category) {
                    ForEach(StudyTips.categories, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
            }
            if category == "Tones" { Section { ToneChart() } }
            Section {
                ForEach(StudyTips.all.filter { $0.category == category }) { tip in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(tip.title).font(.headline)
                        Text(tip.body).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            if category == "Characters" {
                Section("Common radicals") {
                    ForEach(Radicals.meanings.sorted { $0.key < $1.key }, id: \.key) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Text(item.key).font(.title2).frame(width: 36)
                            Text(item.value).font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Tips & tricks")
    }
}

/// The four tone contours drawn as lines, with example syllables you can hear.
struct ToneChart: View {
    private let tones: [(name: String, example: String, pinyin: String, points: [CGPoint])] = [
        ("1st — high, flat", "妈", "mā", [CGPoint(x: 0, y: 0.15), CGPoint(x: 1, y: 0.15)]),
        ("2nd — rising", "麻", "má", [CGPoint(x: 0, y: 0.6), CGPoint(x: 1, y: 0.1)]),
        ("3rd — dip", "马", "mǎ", [CGPoint(x: 0, y: 0.55), CGPoint(x: 0.5, y: 0.9), CGPoint(x: 1, y: 0.35)]),
        ("4th — falling", "骂", "mà", [CGPoint(x: 0, y: 0.1), CGPoint(x: 1, y: 0.9)]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap to hear: mā má mǎ mà").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(tones.indices, id: \.self) { i in
                    let t = tones[i]
                    Button { Speaker.shared.speak(t.example, speed: .slow) } label: {
                        VStack(spacing: 6) {
                            Path { path in
                                let w: CGFloat = 60, h: CGFloat = 40
                                path.move(to: CGPoint(x: t.points[0].x * w, y: t.points[0].y * h))
                                for p in t.points.dropFirst() { path.addLine(to: CGPoint(x: p.x * w, y: p.y * h)) }
                            }
                            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .frame(width: 60, height: 40)
                            Text(t.pinyin).font(.title3.bold())
                            Text(t.name).font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
