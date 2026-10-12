import SwiftUI
import SwiftData

// MARK: - Learn hub

struct LearnView: View {
    @Query private var progress: [CardProgress]
    @Query private var attempts: [Attempt]
    @AppStorage(Settings.level) private var level = 1

    private static let levelInfo: [Int: (title: String, goal: String)] = [
        1: ("Foundations", "Greetings, numbers, family, food, time and simple sentences."),
        2: ("Everyday communication", "Routines, shopping, transport, descriptions and comparisons."),
        3: ("Connected Chinese", "Longer dialogues, short passages and more complex grammar."),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Level", selection: $level) {
                        ForEach(1...3, id: \.self) { Text("HSK \($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if let info = Self.levelInfo[level] {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("HSK \(level)").font(.caption.bold()).opacity(0.85)
                            Text(info.title).font(.title2.bold())
                            Text(info.goal).font(.subheadline).opacity(0.9)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Theme.levelGradient(level), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }
                }

                Section {
                    NavigationLink { StudyTipsView() } label: {
                        Label("Tips & tricks — tones, characters, exam strategy", systemImage: "lightbulb.fill")
                            .foregroundStyle(Theme.gold)
                    }
                }

                Section("Vocabulary") {
                    NavigationLink { WordListView(level: level) } label: {
                        Label("\(VocabularyStore.words(level: level).count) words", systemImage: "character.book.closed")
                    }
                }

                Section("Grammar · \(GrammarStore.points(level: level).count) lessons") {
                    NavigationLink { GrammarPracticeView(point: mixedPractice) } label: {
                        Label("Mixed grammar quiz", systemImage: "shuffle").bold()
                    }
                    ForEach(GrammarStore.points(level: level)) { point in
                        NavigationLink { GrammarLessonView(point: point) } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(point.title)
                                    Text(point.summary).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if attempts.contains(where: { $0.itemID == point.id }) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Learn")
        }
    }

    /// All exercises of this level's grammar points, mixed together.
    private var mixedPractice: GrammarPoint {
        let points = GrammarStore.points(level: level)
        return GrammarPoint(
            id: "g-mix-\(level)", level: level, title: "HSK \(level) grammar mix", summary: "Mixed practice",
            explanation: "Mixed practice from all HSK \(level) grammar lessons.", examples: [], commonMistake: "",
            builders: Array(points.flatMap(\.builders).shuffled().prefix(5)),
            blanks: Array(points.flatMap(\.blanks).shuffled().prefix(7)))
    }
}

// MARK: - Vocabulary

struct WordListView: View {
    let level: Int
    @Query private var progress: [CardProgress]
    @State private var search = ""

    private var words: [Word] {
        let all = VocabularyStore.words(level: level)
        guard !search.isEmpty else { return all }
        return all.filter {
            $0.hanzi.contains(search) || $0.english.localizedCaseInsensitiveContains(search)
                || Pinyin.normalize($0.pinyin).contains(Pinyin.normalize(search))
        }
    }

    var body: some View {
        List(words) { word in
            NavigationLink { WordDetailView(word: word) } label: {
                HStack {
                    Group {
                        if let pic = word.emoji { PictureView(picture: pic, size: 40, corner: 8, scaled: false) }
                        else { Color.clear }
                    }
                    .frame(width: 40, height: 40)
                    Text(word.hanzi).font(.title3).frame(minWidth: 60, alignment: .leading)
                    VStack(alignment: .leading) {
                        Text(word.pinyin).foregroundStyle(.tint)
                        Text(word.english).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    status(for: word)
                }
            }
        }
        .searchable(text: $search, prompt: "Hanzi, pinyin or English")
        .navigationTitle("HSK \(level) words")
    }

    @ViewBuilder private func status(for word: Word) -> some View {
        if let p = progress.first(where: { $0.wordID == word.id }) {
            if p.isMastered { Image(systemName: "star.fill").foregroundStyle(.yellow) }
            else if p.isLearning { Image(systemName: "circle.lefthalf.filled").foregroundStyle(.orange) }
        }
    }
}

struct WordDetailView: View {
    let word: Word

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    if let pic = word.emoji { PictureView(picture: pic, layout: .banner(260), corner: 24, zoom: .tap) }
                    Text(word.hanzi).hanziFont(80)
                    PinyinText(word.pinyin, font: .title, color: Theme.accent)
                    Text(word.english).font(.title3)
                    AudioButtons(text: word.hanzi)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            if let ex = word.example {
                Section("Example") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(ex).font(.title3)
                            Spacer()
                            AudioButtons(text: ex)
                        }
                        if let p = word.examplePinyin { PinyinText(p) }
                        if let e = word.exampleEnglish { Text(e) }
                    }
                }
            }
            if let hint = Radicals.hint(for: word) {
                Section("Memory trick") {
                    Label(hint, systemImage: "lightbulb.fill").foregroundStyle(.primary)
                    let family = VocabularyStore.all.filter { $0.radical == word.radical && $0.id != word.id }.prefix(8)
                    if !family.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Other words with \(word.radical ?? ""):").font(.caption).foregroundStyle(.secondary)
                            Text(family.map { "\($0.hanzi) \($0.english.components(separatedBy: ";").first ?? "")" }.joined(separator: " · "))
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle(word.hanzi)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Speaker.shared.autoSpeak(word.hanzi) }
    }
}

// MARK: - Grammar lesson

struct GrammarLessonView: View {
    let point: GrammarPoint

    var body: some View {
        List {
            Section {
                Text(point.explanation)
            }
            Section("Examples") {
                ForEach(point.examples, id: \.self) { ex in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(ex.chinese).font(.title3)
                            Spacer()
                            AudioButtons(text: ex.chinese)
                        }
                        PinyinText(ex.pinyin)
                        Text(ex.english).font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
            Section("Common mistake") {
                Label(point.commonMistake, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            if !point.tips.isEmpty {
                Section("Tricks to remember") {
                    ForEach(point.tips, id: \.self) { tip in
                        Label(tip, systemImage: "lightbulb.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                }
            }
            Section {
                NavigationLink { GrammarPracticeView(point: point) } label: {
                    Label("Practice: \(point.builders.count + point.blanks.count) exercises", systemImage: "pencil")
                        .bold()
                }
            }
        }
        .navigationTitle(point.title)
        .studyTimer()
    }
}

// MARK: - Grammar practice (sentence builder + fill in the blank)

struct GrammarPracticeView: View {
    let point: GrammarPoint

    private enum Exercise: Hashable {
        case build(SentenceBuilder)
        case blank(FillBlank)
    }

    @Environment(\.modelContext) private var context
    @State private var exercises: [Exercise] = []
    @State private var index = 0
    @State private var picked: [Int] = []          // indices into shuffledTokens
    @State private var shuffledTokens: [String] = []
    @State private var choice: String?
    @State private var checked = false
    @State private var score = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if exercises.isEmpty {
                ProgressView()
            } else if index >= exercises.count {
                Spacer()
                Text("\(score) / \(exercises.count)").font(.system(size: 56, weight: .bold)).frame(maxWidth: .infinity)
                Text(score == exercises.count ? "Perfect! 🎉" : "Review the lesson and try again.")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Button("Try again") { start() }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                Spacer()
            } else {
                ProgressView(value: Double(index), total: Double(exercises.count))
                switch exercises[index] {
                case .build(let b): builderView(b)
                case .blank(let f): blankView(f)
                }
                Spacer()
                Button(checked ? "Next" : "Check") { checked ? next() : check() }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(!checked && !canCheck)
            }
        }
        .padding()
        .navigationTitle(point.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if exercises.isEmpty { start() } }
        .studyTimer()
    }

    private var canCheck: Bool {
        switch exercises[index] {
        case .build: !picked.isEmpty
        case .blank: choice != nil
        }
    }

    // Sentence builder

    private func builderView(_ b: SentenceBuilder) -> some View {
        let built = picked.map { shuffledTokens[$0] }.joined()
        let right = built == b.answer
        return VStack(alignment: .leading, spacing: 16) {
            Text("Arrange the words to say:").font(.subheadline).foregroundStyle(.secondary)
            Text(b.english).font(.title3.bold())

            // Answer line
            HStack {
                Text(built.isEmpty ? " " : built).font(.title2)
                Spacer()
                if !picked.isEmpty && !checked {
                    Button { picked.removeLast() } label: { Image(systemName: "delete.left") }
                }
            }
            .padding()
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 10) {
                ForEach(shuffledTokens.indices, id: \.self) { i in
                    Button(shuffledTokens[i]) { picked.append(i) }
                        .buttonStyle(.bordered)
                        .disabled(picked.contains(i) || checked)
                }
            }

            if checked {
                Label(right ? "Correct!" : "Correct order: \(b.answer)",
                      systemImage: right ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(right ? .green : .red)
                if !right { Text(point.commonMistake).font(.footnote).foregroundStyle(.secondary) }
            }
        }
    }

    // Fill in the blank

    private func blankView(_ f: FillBlank) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fill in the blank").font(.subheadline).foregroundStyle(.secondary)
            Text(f.sentence.replacingOccurrences(of: "＿＿", with: checked ? "【\(f.answer)】" : "＿＿"))
                .font(.title2)
            Text(f.english).foregroundStyle(.secondary)
            HStack {
                ForEach(f.options, id: \.self) { opt in
                    Button(opt) { if !checked { choice = opt } }
                        .buttonStyle(.bordered)
                        .tint(checked ? (opt == f.answer ? .green : opt == choice ? .red : .gray)
                                      : (opt == choice ? .accentColor : .gray))
                }
            }
            if checked {
                Label(choice == f.answer ? "Correct!" : "The answer is \(f.answer).",
                      systemImage: choice == f.answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(choice == f.answer ? .green : .red)
                Text(point.explanation).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    // Logic

    private func start() {
        exercises = (point.builders.map(Exercise.build) + point.blanks.map(Exercise.blank)).shuffled()
        index = 0; score = 0
        prepare()
    }

    private func prepare() {
        picked = []; choice = nil; checked = false
        if exercises.indices.contains(index), case .build(let b) = exercises[index] {
            var s = b.tokens.shuffled()
            if s == b.tokens && s.count > 1 { s.reverse() }
            shuffledTokens = s
        }
    }

    private func check() {
        let ok: Bool
        switch exercises[index] {
        case .build(let b): ok = picked.map { shuffledTokens[$0] }.joined() == b.answer
        case .blank(let f): ok = choice == f.answer
        }
        if ok { score += 1 }
        checked = true
        Tracker.record(context, skill: .grammar, itemID: point.id, correct: ok)
    }

    private func next() {
        index += 1
        prepare()
    }
}


/// All grammar lessons of one level (used by the Home "focus" item).
struct GrammarLessonListView: View {
    let level: Int
    var body: some View {
        List(GrammarStore.points(level: level)) { point in
            NavigationLink { GrammarLessonView(point: point) } label: {
                VStack(alignment: .leading) {
                    Text(point.title)
                    Text(point.summary).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("HSK \(level) grammar")
    }
}
